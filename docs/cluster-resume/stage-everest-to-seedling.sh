#!/usr/bin/env bash
#
# stage-everest-to-seedling.sh
# ----------------------------
# Stage the EVEREST databases + test data + configs from acacia onto the
# seedling-prod cluster's MinIO, so everest_nf can run there.
#
#   tki-acacia:pub-everest/<item>  ->  seedling:su-everest-nf/shared/everest/<item>
#
# COPY-ONLY (no deletes): acacia stays canonical; this only adds to the cluster.
# Each item is copied (idempotent, --size-only) then verified with
# `rclone check --one-way --size-only` (every source object present in dest).
#
# REQUIREMENTS: rclone with remotes `tki-acacia` and `seedling` configured.
#   seedling remote (cluster MinIO), if missing, create with:
#     rclone config create seedling s3 provider Minio \
#       endpoint https://s3.seedling.abc-cluster.cloud \
#       access_key_id patricia secret_access_key <SECRET>
#
# USAGE:
#   DRY_RUN=true ./stage-everest-to-seedling.sh                 # preview
#   ITEMS="_configs _samplesheets" ./stage-everest-to-seedling.sh   # small test first
#   nohup ./stage-everest-to-seedling.sh >/dev/null 2>&1 &      # full stage (DBs + data_test)

set -uo pipefail

# ----------------------- config (override via env) -----------------------
SRC="${SRC:-tki-acacia:pub-everest}"
DST="${DST:-seedling:su-everest-nf/shared/everest}"
ITEMS="${ITEMS:-db_dir/everest data_test _configs _samplesheets}"
DRY_RUN="${DRY_RUN:-false}"
TRANSFERS="${TRANSFERS:-8}"
CHECKERS="${CHECKERS:-16}"
LOG_DIR="${LOG_DIR:-$HOME/everest_stage_logs}"
# -------------------------------------------------------------------------

mkdir -p "$LOG_DIR"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
MAIN_LOG="$LOG_DIR/stage-$RUN_TS.log"
DRYFLAG=(); [ "$DRY_RUN" = "true" ] && DRYFLAG=(--dry-run)
RCLONE_COMMON=(--transfers "$TRANSFERS" --checkers "$CHECKERS"
               --retries 5 --low-level-retries 10
               --stats 30s --stats-one-line
               --log-file "$MAIN_LOG" --log-level INFO)
FAILURES=()
log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$MAIN_LOG"; }
fatal(){ log "FATAL: $*"; exit 1; }

command -v rclone >/dev/null 2>&1 || fatal "rclone not found"
rclone listremotes 2>/dev/null | grep -qx "tki-acacia:" || fatal "remote tki-acacia: not configured"
rclone listremotes 2>/dev/null | grep -qx "seedling:"   || fatal "remote seedling: not configured"

log "=== stage EVEREST -> seedling MinIO ==="
log "    SRC=$SRC  DST=$DST  DRY_RUN=$DRY_RUN  items: $ITEMS"

stage_item(){
  local item="$1" s="$SRC/$1" d="$DST/$1"
  log "--------------------------------------------------------------"
  log "STAGE: $s  ->  $d"
  if [ -z "$(rclone lsf "$s" --files-only -R 2>/dev/null | head -1)" ]; then
    log "WARN: source empty/absent, skipping: $s"; FAILURES+=("missing:$item"); return 1
  fi
  if ! rclone copy "$s" "$d" --size-only "${RCLONE_COMMON[@]}" "${DRYFLAG[@]}"; then
    log "ERROR: copy failed: $item"; FAILURES+=("copy:$item"); return 1
  fi
  if [ "$DRY_RUN" = "true" ]; then log "DRY-RUN: would verify $item"; return 0; fi
  if rclone check "$s" "$d" --one-way --size-only --log-file "$MAIN_LOG" --log-level INFO; then
    log "VERIFIED OK: $item"
  else
    log "ERROR: verification FAILED: $item"; FAILURES+=("verify:$item"); return 1
  fi
}

for item in $ITEMS; do stage_item "$item"; done

log "=== staging finished ==="
if [ "$DRY_RUN" != "true" ]; then rclone size "$DST" 2>/dev/null | tee -a "$MAIN_LOG"; fi
if [ "${#FAILURES[@]}" -eq 0 ]; then
  log "RESULT: SUCCESS — all items staged & verified to $DST"; exit 0
else
  log "RESULT: COMPLETED WITH ${#FAILURES[@]} FAILURE(S):"; for f in "${FAILURES[@]}"; do log "   - $f"; done; exit 1
fi
