#!/bin/sh
#ABC --name=everest-stage-cohort-full
#ABC --namespace=su-everest-nf
#ABC --driver=docker
#ABC --driver.config.image=rclone/rclone:1.68.2
#ABC --driver.config.entrypoint=["/usr/bin/env"]   # image ENTRYPOINT is rclone; run the script via env
#ABC --cores=2
#ABC --mem=2G
#ABC --time=24:00:00
#ABC --secret=ACACIA_ACCESS_KEY_ID=acacia-access-key
#ABC --secret=ACACIA_SECRET_ACCESS_KEY=acacia-secret-key
#ABC --secret=SEEDLING_ACCESS_KEY_ID=seedling-s3-access-key
#ABC --secret=SEEDLING_SECRET_ACCESS_KEY=seedling-s3-secret-key
#
# stage-cohort-full.sh
# --------------------
# Stage the FULL-SIZE reads for the cohort_full profile from acacia onto the seedling MinIO:
#   <acacia>:pub-everest/data_test/<modality>/...  ->  <seedling>:su-everest-nf/shared/everest/test_data/reads_full/<dest>/...
# Destination layout matches assets/test_samplesheets/cohort_full.csv. COPY-ONLY (no deletes).
#
# AS A CLUSTER JOB (abc >= v0.1.83; the #ABC lines above):
#   abc job run docs/cluster-resume/stage-cohort-full.sh --node-pool platform
# Credentials come from abc secrets in su-everest-nf (rendered by Nomad at alloc start, never
# in the job definition): acacia-access-key, acacia-secret-key, seedling-s3-access-key,
# seedling-s3-secret-key. Until all four exist the job stays pending (abc job trace shows
# "Missing: nomad.var.block(...)") and starts by itself once they are set.
#
# LOCALLY: with rclone remotes `tki-acacia` and `seedling` configured, just run it
# (DRY_RUN=true for preflight only). Nothing here embeds credentials.
#
# The SOURCE paths follow RESUME-ON-ABC-CLUSTER.md and have NOT been verified against acacia:
# PREFLIGHT checks every source object first and stops if any is missing.

set -u

ACACIA_ENDPOINT="${ACACIA_ENDPOINT:-https://projects.pawsey.org.au}"
SEEDLING_ENDPOINT="${SEEDLING_ENDPOINT:-https://s3.seedling.abc-cluster.cloud}"

# In a job, define the remotes from the injected secrets (rclone env-var remotes).
if [ -n "${ACACIA_ACCESS_KEY_ID:-}" ]; then
  export RCLONE_CONFIG_ACACIA_TYPE=s3 RCLONE_CONFIG_ACACIA_PROVIDER=Ceph
  export RCLONE_CONFIG_ACACIA_ENDPOINT="$ACACIA_ENDPOINT"
  export RCLONE_CONFIG_ACACIA_ACCESS_KEY_ID="$ACACIA_ACCESS_KEY_ID"
  export RCLONE_CONFIG_ACACIA_SECRET_ACCESS_KEY="$ACACIA_SECRET_ACCESS_KEY"
  SRC_REMOTE="${SRC_REMOTE:-acacia}"
fi
if [ -n "${SEEDLING_ACCESS_KEY_ID:-}" ]; then
  export RCLONE_CONFIG_SEEDLING_TYPE=s3 RCLONE_CONFIG_SEEDLING_PROVIDER=Minio
  export RCLONE_CONFIG_SEEDLING_ENDPOINT="$SEEDLING_ENDPOINT"
  export RCLONE_CONFIG_SEEDLING_ACCESS_KEY_ID="$SEEDLING_ACCESS_KEY_ID"
  export RCLONE_CONFIG_SEEDLING_SECRET_ACCESS_KEY="$SEEDLING_SECRET_ACCESS_KEY"
fi
SRC_REMOTE="${SRC_REMOTE:-tki-acacia}"
DST_REMOTE="${DST_REMOTE:-seedling}"

SRC="${SRC:-$SRC_REMOTE:pub-everest/data_test}"
DST="${DST:-$DST_REMOTE:su-everest-nf/shared/everest/test_data/reads_full}"
DRY_RUN="${DRY_RUN:-false}"
LOGDIR="${NOMAD_ALLOC_DIR:-$HOME/everest_stage_logs}"
LOG="${LOG:-$LOGDIR/cohort-full-$(date +%Y%m%d-%H%M%S).log}"
mkdir -p "$(dirname "$LOG")"

# "<source path under $SRC>|<dest path under $DST>", one per line
FILES='SR_PE/DNA/pass/PRJEB32062/ERR3274620_R1.fastq.gz|shortreads/PRJEB32062/ERR3274620_R1.fastq.gz
SR_PE/DNA/pass/PRJEB32062/ERR3274620_R2.fastq.gz|shortreads/PRJEB32062/ERR3274620_R2.fastq.gz
SR_PE/DNA/pass/PRJNA316588/SRR5110531_R1.fastq.gz|shortreads/PRJNA316588/SRR5110531_R1.fastq.gz
SR_PE/DNA/pass/PRJNA316588/SRR5110531_R2.fastq.gz|shortreads/PRJNA316588/SRR5110531_R2.fastq.gz
SR_PE/RNA/pass/PRJNA493096/SRR8322173_R1.fastq.gz|shortreads_rna/PRJNA493096/SRR8322173_R1.fastq.gz
SR_PE/RNA/pass/PRJNA493096/SRR8322173_R2.fastq.gz|shortreads_rna/PRJNA493096/SRR8322173_R2.fastq.gz
SR_SE/DNA/PRJNA258008/SRR1553676_R1.fastq.gz|shortreads_se/PRJNA258008/SRR1553676_R1.fastq.gz
SR_SE/RNA/PRJEB28158/ERR2732537_R1.fastq.gz|shortreads_se_rna/PRJEB28158/ERR2732537_R1.fastq.gz
LR_NP/PRJNA744354_S/SRR15057753_R1.fastq.gz|longreads_np/PRJNA744354_S/SRR15057753_R1.fastq.gz
LR_PB/PRJEB32062_S/ERR4661016_R1.fastq.gz|longreads_pb/PRJEB32062_S/ERR4661016_R1.fastq.gz'
NFILES=$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')

log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }
command -v rclone >/dev/null || { log "FATAL: rclone not found"; exit 1; }
for r in "$SRC_REMOTE" "$DST_REMOTE"; do
  envtype="$(printenv "RCLONE_CONFIG_$(printf '%s' "$r" | tr 'a-z-' 'A-Z_')_TYPE" || true)"
  [ -n "$envtype" ] || rclone listremotes | grep -qx "$r:" || { log "FATAL: remote $r: not configured"; exit 1; }
done

log "PREFLIGHT: checking $NFILES source objects under $SRC"
missing=0; total=0
while IFS='|' read -r s d; do
  sz="$(rclone size --json "$SRC/$s" 2>/dev/null | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')"
  if [ -z "$sz" ] || [ "$sz" = "0" ]; then log "  MISSING/EMPTY: $s"; missing=$((missing+1))
  else log "  ok  $(( sz / 1048576 )) MiB  $s"; total=$((total+sz)); fi
done <<EOF
$FILES
EOF
log "PREFLIGHT: $(( total / 1073741824 )) GiB to copy, $missing missing"
if [ "$missing" -ne 0 ]; then
  log "FATAL: fix the SOURCE paths above and rerun. Listing $SRC to help:"
  rclone lsf -R --files-only "$SRC" 2>&1 | grep -E 'ERR3274620|SRR5110531|SRR8322173|SRR1553676|ERR2732537|SRR15057753|ERR4661016' | tee -a "$LOG"
  exit 1
fi
[ "$DRY_RUN" = "true" ] && { log "DRY_RUN: stopping after preflight"; exit 0; }

fail=0
while IFS='|' read -r s d; do
  log "COPY $s -> $d"
  rclone copyto "$SRC/$s" "$DST/$d" --size-only --retries 5 --low-level-retries 10 --stats 5m --stats-one-line --log-level NOTICE 2>&1 | tee -a "$LOG" || true
  # rclone check wants directories; compare exact byte counts of the two objects instead.
  sb="$(rclone size --json "$SRC/$s" 2>>"$LOG" | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')"
  db="$(rclone size --json "$DST/$d" 2>>"$LOG" | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')"
  if [ -n "$sb" ] && [ "$sb" = "$db" ]; then log "  verified $d ($sb bytes)"
  else log "  VERIFY FAILED: $d (source ${sb:-?} bytes, dest ${db:-?} bytes)"; fail=$((fail+1)); fi
done <<EOF
$FILES
EOF
if [ "$fail" -eq 0 ]; then log "DONE: all $NFILES files staged and verified"; else log "DONE WITH $fail FAILURES"; exit 1; fi
