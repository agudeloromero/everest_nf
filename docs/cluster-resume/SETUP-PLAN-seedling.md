# Setup plan — EVEREST test data + databases on seedling (su-everest-nf)

Goal: stage the EVEREST **databases (33 GiB)** and **test data (~46 GiB)** onto the
seedling-prod cluster so `everest_nf` can run there, using Patricia's context.

## Context (added to `~/.abc/config.yaml`)
```
seedling-patricia
  endpoint   : https://nomad.seedling.abc-cluster.cloud
  minio (s3) : https://s3.seedling.abc-cluster.cloud   (access_key: patricia)
  namespace  : su-everest-nf      datacenters: [seedling-prod]
  head_pool  : platform           worker_pool: compute
```
Source of truth for the data = **OCI Sydney** `oci-s3-phd-au:everest` (persists after
oci-aus is wiped), so this setup is **not** blocked by the server decommission.

---

## Phase A — Activate + inspect (read-only)
```bash
abc auth context use seedling-patricia      # switches active context
abc doctor                                  # end-to-end health check on the context
abc data list                               # what buckets/prefixes exist for su-everest-nf
abc infra storage                           # storage inventory / sizes
```
Determine the target bucket/prefix for the namespace (likely `su-everest-nf`).
Create one if needed:
```bash
abc data make-bucket su-everest-nf          # if not already present
```

## Phase B — Transfer OCI → seedling MinIO
Two viable mechanisms; **B1 is preferred** (cluster-native, no laptop round-trip).

### B1. Server-side copy via Nomad job (`abc data copy` / `fetch`)
Runs rclone/s5cmd as a job on the cluster, pulling from OCI straight into MinIO.
Requires the **OCI read credentials** to be available to the job (the
`oci-s3-phd-au` access_key/secret_key + endpoint
`https://frvf3pq2ql1y.compat.objectstorage.ap-sydney-1.oci.customer-oci.com`).
Provide them via `abc secrets` or an rclone-config secret, then:
```bash
# databases + references (33 GiB)
abc data copy  s3://everest/db_dir/everest  s3://su-everest-nf/everest/db_dir/everest  --source-remote oci-s3-phd-au
# raw test fastqs (~46 GiB)
abc data copy  s3://everest/data_test       s3://su-everest-nf/everest/data_test       --source-remote oci-s3-phd-au
```
*(exact flags TBD against `abc data copy --help` — confirm how it takes a non-default
source remote/credentials; `abc data fetch <s3-uri>` is the single-source variant.)*

### B2. Fallback — rclone from any host with both remotes
From a box that can reach OCI + seedling MinIO (a seedling head node, or locally):
```bash
rclone config create seedling s3 provider=Minio \
  endpoint=https://s3.seedling.abc-cluster.cloud \
  access_key_id=patricia secret_access_key=<secret>
rclone copy oci-s3-phd-au:everest/db_dir/everest seedling:su-everest-nf/everest/db_dir/everest --transfers 8 --checkers 16
rclone copy oci-s3-phd-au:everest/data_test      seedling:su-everest-nf/everest/data_test      --transfers 8 --checkers 16
rclone copy oci-s3-phd-au:everest/_configs       seedling:su-everest-nf/everest/_configs
```
Then **verify**: `rclone check oci-s3-phd-au:everest/db_dir/everest seedling:su-everest-nf/everest/db_dir/everest --one-way --size-only`.

### Also push the small text assets (already in this repo)
```bash
abc data push docs/cluster-resume/samplesheets  s3://su-everest-nf/everest/_samplesheets
abc data push docs/cluster-resume/params        s3://su-everest-nf/everest/_configs/params
```

## Phase C — Decide DB access pattern for the pipeline  ⚠️ key design call
EVEREST DBs are **directory** `path` inputs (checkv 6 G, virsorter 13 G, mmseqs 3.4/1.2 G…).
- **Option 1 — shared volume (recommended for big DBs):** stage the DB tree once onto a
  Nomad host volume / shared FS mounted into every compute container; reference by local
  path. Avoids Nextflow S3-staging 13 G of virsorter into every task's work dir.
- **Option 2 — S3 inputs:** point params at `s3://su-everest-nf/everest/db_dir/everest/...`
  and let Nextflow stage per task. Simpler, but heavy for large DBs run repeatedly.
Pick per how nf-nomad mounts storage on seedling (ties into the Phase-1 executor profile).

## Phase D — Rewrite params for the cluster
Start from `docs/cluster-resume/params/params.data_test.yaml` and:
- repoint **every** DB/reference path (`checkv_db`, `mmseq_viral_db_*`, `virsorter_db`,
  `tax_*`, `baltimore_db`, `adaptor`, `genome`/`fasta`/`transcriptome`) to the chosen
  location (shared-volume path or `s3://su-everest-nf/...`). All are mandatory — no skip logic.
- drop `pharokka_db` / `diamond_db_aa` (don't exist; unused).
- rewrite the samplesheet path prefix from `/home/opc/EVEREST/data_test/...` to the
  cluster location. Begin with `test_publication.csv` (8 DNA PE samples, PRJNA319556).

## Phase E — Smoke test, then scale
```bash
abc pipeline run ...   # everest_nf head job → Nomad, namespace su-everest-nf,
                       # -r vrhyme-summaries, NXF_VER=25.10.5, params-file above
```
1. Single short-read sample (subset of `test_publication.csv`).
2. Full `test_publication.csv` cohort → validate `EVEREST_nt_summary.txt` / `EVEREST_aa_summary.txt`.
3. Long-read + contig via `mixed.full.csv`.

## Open items / decisions
- **OCI creds for B1** — how to hand the `oci-s3-phd-au` keys to a cluster job (secret vs presigned URLs). If awkward, use B2.
- **Target bucket name** — confirm whether `su-everest-nf` bucket exists or must be created (Phase A).
- **DB access pattern** — Option 1 vs 2 (Phase C); depends on the nf-nomad profile (Phase 1).
- This needs the **Phase-1 nf-nomad executor profile** before `abc pipeline run` will work end-to-end.
