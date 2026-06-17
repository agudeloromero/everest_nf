#!/usr/bin/env bash
#
# consolidate-everest-to-acacia.sh
# ---------------------------------
# Consolidate all EVEREST data into  tki-acacia:pub-everest.
#
#   1. COPY the complete DB / test-data / config set from OCI
#      (oci-s3-phd-au:everest)  ->  pub-everest/   [OCI source is NEVER deleted]
#   2. MOVE the everest data already scattered on acacia into pub-everest/
#      using copy -> verify -> *lazy* delete.
#
# SAFETY MODEL (important):
#   * Nothing is ever deleted with `rclone move`. Each item is COPIED, then
#     verified with `rclone check --one-way` (every source object must exist
#     in the destination). Only if that check PASSES *and* DELETE_SOURCE=true
#     is the source removed. A failed/partial transfer leaves the source intact.
#   * OCI sources are copy-only and never deleted, regardless of DELETE_SOURCE.
#   * Idempotent & resumable: re-running skips already-transferred objects.
#
# USAGE:
#   # dry run first (shows what would transfer, deletes nothing):
#   DRY_RUN=true ./consolidate-everest-to-acacia.sh
#
#   # real run in the background, logging to a file:
#   nohup ./consolidate-everest-to-acacia.sh >/dev/null 2>&1 &
#   tail -f ~/everest_consolidate_logs/consolidate-*.log
#
#   # copy everything but keep all sources (no deletion at all):
#   DELETE_SOURCE=false ./consolidate-everest-to-acacia.sh
#
# REQUIREMENTS: rclone with remotes `oci-s3-phd-au` and `tki-acacia` configured.

set -uo pipefail   # NOT -e: one failed item must not abort the whole batch

# ----------------------- config (override via env) -----------------------
OCI_REMOTE="${OCI_REMOTE:-oci-s3-phd-au}"
ACACIA_REMOTE="${ACACIA_REMOTE:-tki-acacia}"
OCI_SRC="${OCI_SRC:-${OCI_REMOTE}:everest}"
DEST="${DEST:-${ACACIA_REMOTE}:pub-everest}"
DELETE_SOURCE="${DELETE_SOURCE:-true}"     # lazily delete acacia sources after verified copy
DRY_RUN="${DRY_RUN:-false}"                # true = preview only (rclone --dry-run, no deletes)
TRANSFERS="${TRANSFERS:-8}"
CHECKERS="${CHECKERS:-16}"
LOG_DIR="${LOG_DIR:-$HOME/everest_consolidate_logs}"
# -------------------------------------------------------------------------

mkdir -p "$LOG_DIR"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
MAIN_LOG="$LOG_DIR/consolidate-$RUN_TS.log"

DRYFLAG=()
[ "$DRY_RUN" = "true" ] && DRYFLAG=(--dry-run)

RCLONE_COMMON=(--transfers "$TRANSFERS" --checkers "$CHECKERS"
               --retries 5 --low-level-retries 10
               --stats 30s --stats-one-line
               --log-file "$MAIN_LOG" --log-level INFO)

FAILURES=()

log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$MAIN_LOG"; }
fatal(){ log "FATAL: $*"; exit 1; }

# ---- preflight ----------------------------------------------------------
command -v rclone >/dev/null 2>&1 || fatal "rclone not found in PATH"
rclone listremotes 2>/dev/null | grep -qx "${OCI_REMOTE}:"    || fatal "remote ${OCI_REMOTE}: not configured"
rclone listremotes 2>/dev/null | grep -qx "${ACACIA_REMOTE}:" || fatal "remote ${ACACIA_REMOTE}: not configured"

log "=== EVEREST consolidation -> $DEST ==="
log "    DRY_RUN=$DRY_RUN  DELETE_SOURCE=$DELETE_SOURCE  transfers=$TRANSFERS"
log "    log file: $MAIN_LOG"
rclone mkdir "$DEST" 2>>"$MAIN_LOG" || true   # idempotent; bucket may already exist

# verify(SRC DEST [extra check flags]) -> 0 if every source object is present & matches in DEST
verify(){
  local src="$1" dst="$2"; shift 2
  log "VERIFY: rclone check --one-way $* $src -> $dst"
  rclone check "$src" "$dst" --one-way "$@" --log-file "$MAIN_LOG" --log-level INFO
}

# copy_only SRC DEST [extra check flags]   (OCI -> acacia; never deletes source)
copy_only(){
  local src="$1" dst="$2"; shift 2
  log "COPY (keep source): $src  ->  $dst"
  if ! rclone copy "$src" "$dst" "${RCLONE_COMMON[@]}" "${DRYFLAG[@]}"; then
    log "ERROR: copy failed: $src -> $dst"; FAILURES+=("copy:$src"); return 1
  fi
  [ "$DRY_RUN" = "true" ] && { log "DRY-RUN: skip verify $src"; return 0; }
  if verify "$src" "$dst" "$@"; then
    log "VERIFIED OK (source kept): $src -> $dst"
  else
    log "ERROR: verification FAILED: $src -> $dst"; FAILURES+=("verify:$src"); return 1
  fi
}

# move_item SRC DEST KIND   KIND = dir|file|bucket
# copy -> verify -> lazy delete (only if verify passes AND DELETE_SOURCE=true)
move_item(){
  local src="$1" dst="$2" kind="$3"
  log "MOVE ($kind): $src  ->  $dst"
  if ! rclone copy "$src" "$dst" "${RCLONE_COMMON[@]}" "${DRYFLAG[@]}"; then
    log "ERROR: copy failed (source intact): $src -> $dst"; FAILURES+=("copy:$src"); return 1
  fi
  if [ "$DRY_RUN" = "true" ]; then log "DRY-RUN: would verify then (if ok) delete $src"; return 0; fi
  if ! verify "$src" "$dst"; then
    log "ERROR: verification FAILED -> source NOT deleted: $src"; FAILURES+=("verify:$src"); return 1
  fi
  log "VERIFIED OK: $src -> $dst"
  if [ "$DELETE_SOURCE" != "true" ]; then
    log "DELETE_SOURCE=false -> keeping source: $src"; return 0
  fi
  log "LAZY DELETE (verified): $src"
  case "$kind" in
    file)   rclone deletefile "$src" --log-file "$MAIN_LOG" --log-level INFO ;;
    dir)    rclone purge      "$src" --log-file "$MAIN_LOG" --log-level INFO ;;
    bucket) rclone delete     "$src" --log-file "$MAIN_LOG" --log-level INFO   # empties bucket, keeps it
            log "NOTE: left empty bucket $src (remove later with: rclone rmdir $src)" ;;
  esac || { log "ERROR: delete failed (data is safe in $dst): $src"; FAILURES+=("delete:$src"); return 1; }
  log "DONE moved: $src -> $dst"
}

# =========================================================================
# 1) From OCI canonical bucket — COPY ONLY (cross-provider; size-only check
#    avoids false mismatches from differing multipart ETags). Never deleted.
# =========================================================================
copy_only "$OCI_SRC/db_dir/everest" "$DEST/db_dir/everest" --size-only
copy_only "$OCI_SRC/data_test"      "$DEST/data_test"      --size-only
copy_only "$OCI_SRC/_configs"       "$DEST/_configs"       --size-only

# =========================================================================
# 2) EVEREST data already on acacia — MOVE (copy -> verify -> lazy delete)
# =========================================================================
move_item "$ACACIA_REMOTE:aerial/results/EVEREST"            "$DEST/EVEREST"               dir
move_item "$ACACIA_REMOTE:aerial/results/EVEREST_meta"       "$DEST/EVEREST_meta"          dir
move_item "$ACACIA_REMOTE:temp/setonix-everest-32577"        "$DEST/setonix-everest-32577" dir
move_item "$ACACIA_REMOTE:temp/DB_everest__DB_MMSEQ2.tar.gz" "$DEST/legacy_db_tarballs"    file
move_item "$ACACIA_REMOTE:temp/DB_everest__DB_checkv.tar.gz" "$DEST/legacy_db_tarballs"    file

# =========================================================================
# 3) everest-nf bucket (~850 GiB) — MOVE all contents into pub-everest/everest-nf
# =========================================================================
move_item "$ACACIA_REMOTE:everest-nf" "$DEST/everest-nf" bucket

# ----------------------------- summary -----------------------------------
log "=== consolidation finished ==="
if [ "$DRY_RUN" != "true" ]; then
  log "Destination size now:"
  rclone size "$DEST" 2>/dev/null | tee -a "$MAIN_LOG"
fi
if [ "${#FAILURES[@]}" -eq 0 ]; then
  log "RESULT: SUCCESS — all items transferred & verified${DELETE_SOURCE:+ (sources handled per DELETE_SOURCE=$DELETE_SOURCE)}"
  exit 0
else
  log "RESULT: COMPLETED WITH ${#FAILURES[@]} FAILURE(S) — sources for failed items were left intact:"
  for f in "${FAILURES[@]}"; do log "   - $f"; done
  exit 1
fi
