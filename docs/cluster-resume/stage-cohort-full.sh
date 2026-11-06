#!/usr/bin/env bash
#
# stage-cohort-full.sh
# --------------------
# Stage the FULL-SIZE reads for the cohort_full profile from acacia onto the seedling MinIO:
#   tki-acacia:pub-everest/data_test/<modality>/...  ->  seedling:su-everest-nf/shared/everest/test_data/reads_full/<dest>/...
# Destination layout matches assets/test_samplesheets/cohort_full.csv. COPY-ONLY (no deletes).
#
# REQUIREMENTS: rclone with remotes `tki-acacia` and `seedling` already configured (see
# stage-everest-to-seedling.sh). Run it from a host with good egress (e.g. sun-aither): the
# laptop path was ~1 MiB/s. Nothing here embeds credentials.
#
# The SOURCE paths below follow the layout documented in RESUME-ON-ABC-CLUSTER.md and the
# old samplesheets in docs/cluster-resume/samplesheets/; they have NOT been verified against
# acacia. The script first checks every source object exists (PREFLIGHT) and stops if not.
#
# USAGE:
#   DRY_RUN=true ./stage-cohort-full.sh     # preflight + preview only
#   ./stage-cohort-full.sh

set -uo pipefail

SRC="${SRC:-tki-acacia:pub-everest/data_test}"
DST="${DST:-seedling:su-everest-nf/shared/everest/test_data/reads_full}"
DRY_RUN="${DRY_RUN:-false}"
LOG="${LOG:-$HOME/everest_stage_logs/cohort-full-$(date +%Y%m%d-%H%M%S).log}"
mkdir -p "$(dirname "$LOG")"

# "<source path under $SRC>|<dest path under $DST>"
FILES=(
  "SR_PE/DNA/pass/PRJEB32062/ERR3274620_R1.fastq.gz|shortreads/PRJEB32062/ERR3274620_R1.fastq.gz"
  "SR_PE/DNA/pass/PRJEB32062/ERR3274620_R2.fastq.gz|shortreads/PRJEB32062/ERR3274620_R2.fastq.gz"
  "SR_PE/DNA/pass/PRJNA316588/SRR5110531_R1.fastq.gz|shortreads/PRJNA316588/SRR5110531_R1.fastq.gz"
  "SR_PE/DNA/pass/PRJNA316588/SRR5110531_R2.fastq.gz|shortreads/PRJNA316588/SRR5110531_R2.fastq.gz"
  "SR_PE/RNA/pass/PRJNA493096/SRR8322173_R1.fastq.gz|shortreads_rna/PRJNA493096/SRR8322173_R1.fastq.gz"
  "SR_PE/RNA/pass/PRJNA493096/SRR8322173_R2.fastq.gz|shortreads_rna/PRJNA493096/SRR8322173_R2.fastq.gz"
  "SR_SE/DNA/PRJNA258008/SRR1553676_R1.fastq.gz|shortreads_se/PRJNA258008/SRR1553676_R1.fastq.gz"
  "SR_SE/RNA/PRJEB28158/ERR2732537_R1.fastq.gz|shortreads_se_rna/PRJEB28158/ERR2732537_R1.fastq.gz"
  "LR_NP/PRJNA744354_S/SRR15057753_R1.fastq.gz|longreads_np/PRJNA744354_S/SRR15057753_R1.fastq.gz"
  "LR_PB/PRJEB32062_S/ERR4661016_R1.fastq.gz|longreads_pb/PRJEB32062_S/ERR4661016_R1.fastq.gz"
)

log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }
command -v rclone >/dev/null || { log "FATAL: rclone not found"; exit 1; }
for r in tki-acacia seedling; do
  rclone listremotes | grep -qx "$r:" || { log "FATAL: remote $r: not configured"; exit 1; }
done

log "PREFLIGHT: checking ${#FILES[@]} source objects under $SRC"
missing=0; total=0
for pair in "${FILES[@]}"; do
  s="${pair%%|*}"
  sz="$(rclone size --json "$SRC/$s" 2>/dev/null | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')"
  if [ -z "$sz" ] || [ "$sz" = "0" ]; then log "  MISSING/EMPTY: $s"; missing=$((missing+1)); else
    log "  ok  $(( sz / 1048576 )) MiB  $s"; total=$((total+sz)); fi
done
log "PREFLIGHT: $(( total / 1073741824 )) GiB to copy, $missing missing"
[ "$missing" -eq 0 ] || { log "FATAL: fix the SOURCE paths above (rclone lsf $SRC -R | grep <sample>) and rerun"; exit 1; }
[ "$DRY_RUN" = "true" ] && { log "DRY_RUN: stopping after preflight"; exit 0; }

fail=0
for pair in "${FILES[@]}"; do
  s="${pair%%|*}"; d="${pair##*|}"
  log "COPY $s -> $d"
  rclone copyto "$SRC/$s" "$DST/$d" --size-only --retries 5 --low-level-retries 10 --log-file "$LOG" --log-level INFO || { log "  FAILED: $s"; fail=$((fail+1)); }
  rclone check --one-way --size-only "$SRC/$s" "$DST/$d" >>"$LOG" 2>&1 || { log "  VERIFY FAILED: $d"; fail=$((fail+1)); }
done
[ "$fail" -eq 0 ] && log "DONE: all ${#FILES[@]} files staged and verified" || { log "DONE WITH $fail FAILURES"; exit 1; }
