# EVEREST-nf — Resume on abc-cluster

Handoff doc for continuing `everest_nf` testing after decommissioning the
`oci-aus` analysis server (`tki-aerial-ol8`, Sydney). Everything EVEREST-relevant
has been backed up off that box; this file says **where it is**, **what it is**,
and **how to pick the work back up** on abc-cluster.

- **Branch:** `vrhyme-summaries`
- **Date archived:** 2026-06-05
- **Source server:** `oci-aus` = `opc@tki-aerial-ol8` (OCI, `ap-sydney-1`) — being wiped
- **Pin:** run with **`NXF_VER=25.10.5`** (Nextflow 26.x breaks the nf-nomad closure DSL; see `docs`/Phase-0 notes)

---

## 1. Where everything lives now

### OCI object storage — remote `oci-s3-phd-au`, bucket `everest`
Endpoint: `https://frvf3pq2ql1y.compat.objectstorage.ap-sydney-1.oci.customer-oci.com`

| Bucket prefix | Contents | Size | Verified |
|---|---|---|---|
| `everest/db_dir/everest/` | **All EVEREST databases + genome references** | 33 GiB | ✅ 0-diff, 44,241 objects |
| `everest/data_test/` | Raw test FASTQs (`SR_PE/ SR_SE/ LR_NP/ LR_PB/`) | ~46 GiB | ✅ 0-diff (excl. `everest-nf/`) |
| `everest/_configs/` | Run scripts, params, configs, samplesheets (Tower token redacted) | <1 MiB | ✅ |
| `everest/_samplesheets/` | Samplesheet set (pre-existing) | 8 KiB | ✅ |

### Already backed up elsewhere (not re-uploaded)
| Data | Location | Notes |
|---|---|---|
| `everest-nf/PRJ*` pipeline input/output (319 G) | **acacia** `tki-acacia:everest-nf/` | ✅ verified 0-diff one-way, 926 matching files |
| `CAP11520` (398 G) | **acacia** `tki-acacia:aerial/20230227_WGS_AERIAL/CAP11520.tar` | clinical WGS set |
| `setonix-everest-32577` (70 G) | **OCI** `oci-s3-phd-au:aerial/setonix-everest-32577` | byte-identical |

### In this repo (committed copies)
`docs/cluster-resume/` mirrors the small but essential text assets:
```
configs/      everest.oci-setonix.config, run_everest.sh, run_local.sh, run_develop.sh   (tokens redacted)
params/       params.everest.production.yaml, params.data_test.yaml
samplesheets/ 22 samplesheets (authoritative set from EVEREST/_samplesheets/)
```

---

## 2. Databases & references (the critical asset — 33 GiB)

Stored under `oci-s3-phd-au:everest/db_dir/everest/`. Each DB has both an
extracted dir and a `.tar.gz`. Param → path mapping:

| Param | Path under `db_dir/everest/` | Size |
|---|---|---|
| `checkv_db` | `DB_checkv/checkv-db-v1.1` | 6.1 G |
| `mmseq_viral_db_aa` (+ `_ref_name: viral.aa.fnaDB`) | `DB_MMSEQ2_aa` | 3.4 G |
| `mmseq_viral_db_nt` (+ `_ref_name: viral.nt.fnaDB`) | `DB_MMSEQ2_nt` | 1.2 G |
| `virsorter_db` | `DB_virsorter` | 13 G |
| `tax_aa` | `TAX_aa` | 464 M |
| `tax_nt` | `TAX_nt` | 466 M |
| `baltimore_db` | `DB_Baltimore/` (v2 `…16052022_v2.txt` **and** v3 `…20250225_v3.txt`) | 1.9 M |
| `adaptor` | `adaptors/adaptors.fa` | 28 K |
| `genome` / `fasta` / `transcriptome` | `genome/` (`male.hg19.fasta`, `Homo_sapiens.GRCh38.cdna.all.fa`) | 4.4 G |

> ⚠️ `pharokka_db` and `diamond_db_aa` are referenced in the params files but **do
> not exist** on the server — those steps are not exercised by the current
> pipeline. Drop the params or source the DBs if pharokka/diamond are ever wired in.

---

## 3. Config & params

### Configs (`docs/cluster-resume/configs/`)
- **`everest.oci-setonix.config`** — the working process config. Setonix/Pawsey-oriented:
  per-process `resourceLimits`, `errorStrategy = "ignore"`, `SEQKIT_FILTER ext.args = "-m 3000"`,
  `SPADES_DENOVO` 150 GB/8 cpu, `PHAROKKA` 60 GB/8 cpu, `process_high_memory` 200 GB/16 cpu,
  `docker.registry = quay.io`. Contains a commented `singularity { runOptions = "-B …" }`
  block — the template for HPC bind-mounts.
- **`run_everest.sh` / `run_develop.sh` / `run_local.sh`** — invocation patterns
  (`-profile docker` / `test,docker`, `-with-tower`, `-r vrhyme-summaries`, `-resume -latest`).
  Tower token **redacted** — re-export `TOWER_ACCESS_TOKEN` yourself if using Seqera Platform.

### Params (`docs/cluster-resume/params/`)
- **`params.data_test.yaml`** — the **test** config. Input = `test_publication.csv`,
  `max_cpus: 40`, `max_memory: 200.GB`, Baltimore **v3**, and defines the long-read
  toggles the pipeline reads: `skip_longread_qc`, `skip_adapter_trimming`,
  `skip_longread_filtering`, `keep_lambda`, `host_genome`. **Start from this file.**
- **`params.everest.production.yaml`** — production run; input = a detaxizer-filtered
  samplesheet, Baltimore v2.

### What must change for abc-cluster
1. **Repoint every DB/reference path** from `/home/opc/db_dir/everest/...` to wherever
   you stage the DBs on the cluster (or an S3/MinIO path). The pipeline has **no skip
   logic** — *all* DB/reference params are mandatory `path` inputs (Phase-0 finding), so
   every one must resolve or the run won't start.
2. **Executor profile.** Current configs use `-profile docker` (local executor). For
   abc-cluster/seedling, add an **nf-nomad** profile (executor `nomad`, `nomad.client.address`,
   `privileged = false`, host-volume DSL, `NXF_HOME` inside the shared volume) — this is
   Phase 1, not yet written.
3. **Container engine.** Docker on seedling; Singularity/SIF on Setonix/Lengau. Confirm
   biocontainer images exist for virsorter2 / checkv / mmseqs2 / vrhyme (conda-only
   modules won't run under Nomad).

---

## 4. Test data & samplesheets

### Data on OCI (`everest/data_test/`)
```
SR_PE/   short-read paired-end   (BOTH/ DNA/ RNA, each pass/ fail/)
SR_SE/   short-read single-end   (BOTH/ DNA/ RNA)
LR_NP/   long-read Nanopore      (PRJNA744354_S)
LR_PB/   long-read PacBio        (PRJEB32062_S)
```
The 319 G `everest-nf/PRJ*` per-BioProject data is on **acacia** (`tki-acacia:everest-nf/`), not OCI.

### Samplesheet schema (`sample,type,short_read_1,short_read_2,contig,long_read,long_read_platform`)
- `type`: `DNA|RNA` (case-insensitive)
- Short-read PE: fill `short_read_1`+`short_read_2`. SE: `short_read_1` only.
- Long-read: fill `long_read` + `long_read_platform` ∈ `{OXFORD_NANOPORE, OXFORD_NANOPORE_HQ, PACBIO, PACBIO_CLR, PACBIO_HIFI}` (enum is enforced — `nanopore` etc. is rejected).
- Contig: fill `contig` (`.fa`/`.fasta`).

### Which samplesheet to use
| File | Purpose |
|---|---|
| **`test_publication.csv`** | Canonical test — 8 DNA PE samples, PRJNA319556 (matches repo `_resources/test-publication`). Referenced by `params.data_test.yaml`. |
| `test_publication_PRJNA319556.csv` | Fuller PRJNA319556 set |
| `mixed.full.csv` / `mixed.sub.csv` | **Coverage of all input types** (Nanopore + SR-PE DNA + SR-PE RNA) — best for exercising the branch routing fixed in Phase 0 |
| `SRPE_DNA_pass.sub.csv`, `SRSE_*`, `LR_NP*.csv`, `LR_PB.csv` | Per-modality minimal sets |
| `stubs.csv` | Tiny set for `-stub-run` |

> ⚠️ All samplesheet paths are absolute `/home/opc/EVEREST/data_test/...`. Rewrite the
> path prefix to your cluster staging location (or bucket mount) before running.

---

## 5. Fetching onto abc-cluster

The rclone remotes from `oci-aus` (S3-compatible; recreate on the cluster with the same
keys/endpoints). To pull the DBs + test data:
```bash
# databases + references (33 GiB)
rclone copy oci-s3-phd-au:everest/db_dir/everest  ./db_dir/everest  --transfers 8 --checkers 16

# raw test fastqs (~46 GiB)
rclone copy oci-s3-phd-au:everest/data_test       ./data_test       --transfers 8 --checkers 16

# configs / params / samplesheets (also committed in this repo)
rclone copy oci-s3-phd-au:everest/_configs        ./_configs

# (optional) per-BioProject input/output data — lives on acacia
rclone copy tki-acacia:everest-nf/PRJNA319556     ./everest-nf/PRJNA319556
```

---

## 6. Code state (Phase 0 — already done on `vrhyme-summaries`)

Commit `e75a212` fixed the wiring/stub bugs that previously prevented any end-to-end
run. Both short-read and long-read **stub runs pass** (`NXF_VER=25.10.5`, Java 21).
Highlights relevant to real cluster runs:
- Read-type `branch` was always routing everything to short-reads (closure-literal bug)
  → long-read/contig inputs now route correctly.
- `merge_summary_input_ch` bare-path `entry[1]` collision fixed.
- `SUMMARY_PER_SAMPLE` out-of-scope `${prefix}` in output block fixed.
- Long-read host index no longer runs for short-read-only inputs.
- Missing/incorrect stub blocks added across many modules.

## 7. Next steps
1. **Phase 1** — author the nf-nomad/seedling executor profile + verify biocontainer coverage.
2. Stage DBs on the cluster (or wire S3/MinIO paths) and repoint params.
3. Smoke test: `test_publication.csv`, single sample, short-read path.
4. Scale to full cohort + validate the new summary outputs (`EVEREST_nt_summary.txt`, `EVEREST_aa_summary.txt`).
5. Then long-read + contig branches (`mixed.full.csv`).

## Appendix — server inventory at decommission
EVEREST footprint (preserved): `db_dir/everest` (34 G), `EVEREST/data_test` raw fastqs,
`EVEREST/_samplesheets`, run configs/params, `results/everest-nf` (34 M).
Already-safe: `everest-nf/PRJ*`→acacia, `CAP11520`→acacia, `setonix-everest-32577`→OCI aerial.
Redundant/disposable: `data/data-everest-1tb-01` (its `data_test` = 0-diff subset; rest `_deleteme`).
Out of scope (non-EVEREST, **not** verified): `data-xdr-2tb-01`, `results/{detaxizer,mag,taxprofiler}`,
the other ~406 G of `db_dir` (CAT/GTDB/Kraken2/Centrifuge/CheckM2), `ANALYSIS-JNN-XDR`, `magma_test`.
