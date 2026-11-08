# Full-size cohort run (`cohort_full`)

Runs real, un-subsampled data through every input pathway in one run. Prepared 2026-11-05;
**not yet run**. Everything below is unverified against the live cluster until noted.

## Cohort (`assets/test_samplesheets/cohort_full.csv`)

| Sample | Pathway | Source (acacia `pub-everest/data_test/`) |
|---|---|---|
| ERR3274620 | SR paired-end DNA | `SR_PE/DNA/pass/PRJEB32062` |
| SRR5110531 | SR paired-end DNA | `SR_PE/DNA/pass/PRJNA316588` |
| SRR8322173 | SR paired-end **RNA** | `SR_PE/RNA/pass/PRJNA493096` |
| SRR1553676 | SR single-end DNA | `SR_SE/DNA/PRJNA258008` |
| ERR2732537 | SR single-end **RNA** | `SR_SE/RNA/PRJEB28158` |
| SRR15057753 | LR Nanopore | `LR_NP/PRJNA744354_S` |
| ERR4661016 | LR **PacBio** | `LR_PB/PRJEB32062_S` |
| AMR_CONTIG | contig-only, AMR positive control | already staged (`contigs/LAMBDA_AMR_contig.fasta`) |

Chosen to cover SR PE/SE x DNA/RNA, LR ONT/PacBio and contig-only. Swap samples in the CSV freely.

## Steps

1. **Stage the reads** (about 10 files; sizes printed by the preflight). From a host with
   rclone remotes `tki-acacia` and `seedling` and good egress:
   `DRY_RUN=true docs/cluster-resume/stage-cohort-full.sh` then without `DRY_RUN`.
   The source paths follow the documented layout but were not checked against acacia, so the
   preflight may report missing objects; correct the `FILES` array if so.
2. **Set resources** in `docs/cluster-resume/configs/seedling-full.config` (see Sizing).
3. **Launch** (context scoped per command, never `abc auth context use`):
   ```
   ABC_CLI_CONTEXT=seedling-patricia abc pipeline run agudeloromero/everest_nf --revision <rev> \
     --namespace su-everest-nf --profile cohort_full \
     --config docs/cluster-resume/configs/seedling-full.config \
     --env NXF_VER=26.04.4 --env NXF_PLUGINS_DEFAULT=nf-schema@2.5.1 --worker-pool platform
   ```
   Every launch is from scratch (no cross-launch caching), so get the config right first.

## Sizing (needs a decision before launch)

`seedling-full.config` still carries the smoke-test caps (4-16 GB per task, 20 GB limit,
`queueSize = 2`). Full data needs far more: the old Setonix config used 150 GB for SPAdes and
200 GB for `process_high_memory`. The current worker node sizes were not visible to me
(`abc node`/`abc infra` need `--sudo`), so set `resourceLimits`, the per-label memory and
`queueSize` from the real `platform` pool capacity. Also check free space on the `nf-work`
volume and the MinIO quota: the work dir holds every intermediate for all samples.

## Known risks (first time on the cluster)

- **RNA pathway never run on this cluster** with the new profiles. It uses the transcriptome
  host removal (`Homo_sapiens.GRCh38.cdna.all.fa`, minimap2 by default) and is still
  staged per task rather than read from the mounted volume.
- **PacBio** is only samplesheet metadata (no platform-specific code path), so expect it to
  behave as ONT; `PACBIO` vs `PACBIO_HIFI`/`PACBIO_CLR` is not distinguished.
- Production contig cut-off applies (`SEQKIT_FILTER -m 5000`, the module default): small
  contigs/sparse samples can legitimately yield no contigs or no viral contigs. Such samples are
  now dropped from the contig steps with a `[everest] <sample>: ...; skipping` warning instead of
  failing the run (CLEANING_CONTIGS_WF); vRhyme skips cleanly too.
- Wall-clock: the 4-sample lambda test took about 9 h at `queueSize = 2`; full data will take
  much longer.

## What to check afterwards

Same checks as the test matrix: no errored/ignored processes; every sample in
`EVEREST_{nt,aa}_summary.txt` (contig-only samples with blank coverage); per-sample
`bacphlip_life_style/<id>` and `nanoplot/{raw,filtered}/<id>`; `abricate_run/<id>.txt`
reports blaTEM-1 for `AMR_CONTIG`; no output overwritten across samples.
