#!/usr/bin/env bash
#
# migrate-oci-to-acacia.sh
# ------------------------
# Migrate OCI object storage -> acacia, dedup-aware, with copy -> verify -> lazy delete.
#
#   oci-s3-phd-au:everest  ->  tki-acacia:pub-everest    (everest; most already there)
#   oci-s3-phd-au:aerial   ->  tki-acacia:aerial         (~1.775 TiB mixed run outputs)
#
# DEDUP: `rclone copy --size-only` skips any object already present in the
#   destination at the same path+size. So data that is ALREADY duplicated on
#   acacia transfers nothing — it is simply verified and then deleted from OCI.
#   New/missing objects are copied first, then verified, then deleted from OCI.
#
# SAFETY MODEL:
#   * Nothing is deleted from OCI until `rclone check --one-way --size-only`
#     confirms EVERY source object exists (same size) in the destination.
#   * A failed/partial transfer leaves the OCI source intact and is reported.
#   * Idempotent & resumable: re-running skips already-transferred objects and
#     skips buckets whose source is already empty.
#   * Cross-provider (OCI S3 -> Ceph) copies are client-side by nature, so the
#     server-side >5 GiB CopyObject bug does NOT apply here.
#
# VERIFICATION NOTE: cross-provider checks use --size-only (multipart ETags
#   differ between providers, so a full hash check would false-positive). This
#   matches path+size; a same-path/same-size/different-content collision would
#   not be detected, which is vanishingly unlikely for these run/data buckets.
#
# USAGE:
#   DRY_RUN=true ./migrate-oci-to-acacia.sh          # preview, transfers/deletes nothing
#   nohup ./migrate-oci-to-acacia.sh >/dev/null 2>&1 &   # real run (deletes OCI after verify)
#   DELETE_SOURCE=false ./migrate-oci-to-acacia.sh   # copy only, keep OCI sources
#   REMOVE_EMPTY_BUCKET=true ./migrate-oci-to-acacia.sh  # also remove the emptied OCI bucket
#   MIGRATE=everest ./migrate-oci-to-acacia.sh       # run only one (everest|aerial)
#
# REQUIREMENTS: rclone with remotes `oci-s3-phd-au` and `tki-acacia` configured.

set -uo pipefail

# ----------------------- config (override via env) -----------------------
OCI_REMOTE="${OCI_REMOTE:-oci-s3-phd-au}"
ACACIA_REMOTE="${ACACIA_REMOTE:-tki-acacia}"
DELETE_SOURCE="${DELETE_SOURCE:-true}"          # delete OCI source after verified copy
REMOVE_EMPTY_BUCKET="${REMOVE_EMPTY_BUCKET:-false}"  # also rmdir the emptied OCI bucket
DRY_RUN="${DRY_RUN:-false}"
MIGRATE="${MIGRATE:-all}"                        # all | everest | aerial
TRANSFERS="${TRANSFERS:-8}"
CHECKERS="${CHECKERS:-16}"
LOG_DIR="${LOG_DIR:-$HOME/oci_migrate_logs}"
# -------------------------------------------------------------------------

# Migration table:  "SRC_BUCKET|DEST"   (one per line)
MIGRATIONS=(
  "everest|${OCI_REMOTE}:everest|${ACACIA_REMOTE}:pub-everest"
  "aerial|${OCI_REMOTE}:aerial|${ACACIA_REMOTE}:aerial"
)

mkdir -p "$LOG_DIR"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
MAIN_LOG="$LOG_DIR/migrate-$RUN_TS.log"

DRYFLAG=(); [ "$DRY_RUN" = "true" ] && DRYFLAG=(--dry-run)
RCLONE_COMMON=(--transfers "$TRANSFERS" --checkers "$CHECKERS"
               --retries 5 --low-level-retries 10
               --stats 30s --stats-one-line
               --log-file "$MAIN_LOG" --log-level INFO)

FAILURES=()
log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$MAIN_LOG"; }
fatal(){ log "FATAL: $*"; exit 1; }

# ---- preflight ----
command -v rclone >/dev/null 2>&1 || fatal "rclone not found in PATH"
rclone listremotes 2>/dev/null | grep -qx "${OCI_REMOTE}:"    || fatal "remote ${OCI_REMOTE}: not configured"
rclone listremotes 2>/dev/null | grep -qx "${ACACIA_REMOTE}:" || fatal "remote ${ACACIA_REMOTE}: not configured"

log "=== OCI -> acacia migration ==="
log "    DRY_RUN=$DRY_RUN  DELETE_SOURCE=$DELETE_SOURCE  REMOVE_EMPTY_BUCKET=$REMOVE_EMPTY_BUCKET  MIGRATE=$MIGRATE"
log "    log file: $MAIN_LOG"

# migrate_bucket NAME SRC DEST
migrate_bucket(){
  local name="$1" src="$2" dst="$3"
  log "--------------------------------------------------------------"
  log "MIGRATE [$name]: $src  ->  $dst"

  # re-run safety: source already empty (a previous run finished + deleted it)
  if [ -z "$(rclone lsf "$src" --files-only -R 2>/dev/null | head -1)" ]; then
    log "SKIP [$name]: source empty/absent (already migrated): $src"; return 0
  fi

  local srcsize; srcsize="$(rclone size "$src" 2>/dev/null | grep 'Total size' || echo '?')"
  log "    source $srcsize"
  rclone mkdir "$dst" 2>>"$MAIN_LOG" || true   # ensure dest bucket exists (idempotent)

  # COPY (dedup via --size-only: skips objects already present in dest)
  if ! rclone copy "$src" "$dst" --size-only "${RCLONE_COMMON[@]}" "${DRYFLAG[@]}"; then
    log "ERROR [$name]: copy failed (OCI source intact): $src"; FAILURES+=("copy:$src"); return 1
  fi
  if [ "$DRY_RUN" = "true" ]; then
    log "DRY-RUN [$name]: would verify then (if ok) delete OCI source $src"; return 0
  fi

  # VERIFY: every source object must exist (same size) in dest
  log "VERIFY [$name]: rclone check --one-way --size-only $src -> $dst"
  if ! rclone check "$src" "$dst" --one-way --size-only --log-file "$MAIN_LOG" --log-level INFO; then
    log "ERROR [$name]: verification FAILED -> OCI source NOT deleted: $src"; FAILURES+=("verify:$src"); return 1
  fi
  log "VERIFIED OK [$name]: all of $src present in $dst"

  if [ "$DELETE_SOURCE" != "true" ]; then
    log "DELETE_SOURCE=false -> keeping OCI source: $src"; return 0
  fi

  # LAZY DELETE from OCI (only reached after successful verify)
  log "LAZY DELETE (verified) from OCI: $src"
  if ! rclone delete "$src" --log-file "$MAIN_LOG" --log-level INFO; then
    log "ERROR [$name]: delete failed (data is safe in $dst): $src"; FAILURES+=("delete:$src"); return 1
  fi
  if [ "$REMOVE_EMPTY_BUCKET" = "true" ]; then
    if rclone rmdir "$src" 2>>"$MAIN_LOG"; then
      log "removed empty OCI bucket: $src"
    else
      log "NOTE: could not rmdir $src (left empty; remove manually if desired)"
    fi
  else
    log "NOTE: left empty OCI bucket $src (remove later: rclone rmdir $src)"
  fi
  log "DONE migrated [$name]: $src -> $dst"
}

for row in "${MIGRATIONS[@]}"; do
  IFS='|' read -r name src dst <<< "$row"
  if [ "$MIGRATE" != "all" ] && [ "$MIGRATE" != "$name" ]; then
    log "SKIP [$name]: not selected (MIGRATE=$MIGRATE)"; continue
  fi
  migrate_bucket "$name" "$src" "$dst"
done

# ----------------------------- summary -----------------------------------
log "=== migration finished ==="
if [ "${#FAILURES[@]}" -eq 0 ]; then
  log "RESULT: SUCCESS — all selected buckets migrated & verified (OCI sources handled per DELETE_SOURCE=$DELETE_SOURCE)"
  exit 0
else
  log "RESULT: COMPLETED WITH ${#FAILURES[@]} FAILURE(S) — OCI sources for failed items left intact:"
  for f in "${FAILURES[@]}"; do log "   - $f"; done
  exit 1
fi
