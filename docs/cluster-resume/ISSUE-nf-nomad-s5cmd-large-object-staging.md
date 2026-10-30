# nf-nomad-s5cmd: large path-input staging fails with `IncompleteBody` on seedling MinIO

## Summary
On the abc-cluster **seedling-prod** cluster, Nextflow tasks that declare a **large
reference-DB directory as a `path` input** fail during **stage-in**. The nf-nomad-s5cmd
plugin stages per-task inputs with an **S3→S3 `s5cmd cp`**, and that copy fails for
large objects with:

```
ERROR "cp s3://.../checkv_hmms/37.hmm s3://su-everest-nf/user/<2c>/<hash>/inputs/.../37.hmm":
  IncompleteBody: You did not provide the number of bytes specified by the
  Content-Length HTTP header. status code: 400, request id: ..., host id: ...
```

Hit while running the `everest_nf` pipeline (CHECKV_VIRAL_SEQ staging the CheckV DB).
The same will hit VirSorter2 (13 GB DB) and any other large path-input.

## Environment
- Cluster: seedling-prod, namespace `su-everest-nf`, Nomad batch tasks.
- Plugin: nf-nomad-s5cmd (per-task bootstrap runs `s5cmd` for stage-in and EXIT-trap push-back).
- s5cmd: **v2.3.0-991c9fb** at `/nxf-work/bin/s5cmd` (host-volume mounted).
- Object store: MinIO at `https://s3.seedling.abc-cluster.cloud` (plugin calls it with
  `--endpoint-url https://s3.seedling.abc-cluster.cloud --no-verify-ssl --log error -r 10 -numworkers 256`).
- Creds (for repro): `~/.abc/config.yaml` → `contexts.seedling-patricia.admin.services.minio`
  (access_key/secret_key); export as `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`.
- Run from host `sun-aither` (has s5cmd + egress).

## Reproduction (minimal, deterministic)
A single large object S3→S3 copy fails:
```
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...    # seedling-patricia minio creds
S5="/nxf-work/bin/s5cmd --endpoint-url https://s3.seedling.abc-cluster.cloud --no-verify-ssl --log error -r 10 -numworkers 256"
$S5 cp \
  s3://su-everest-nf/shared/everest/db_dir/everest/DB_checkv/checkv-db-v1.1/hmm_db/checkv_hmms/37.hmm \
  s3://su-everest-nf/user/patricia/_cvtest/37.hmm
# -> IncompleteBody: ...Content-Length... 400 ; destination object is NOT created.
# Note: s5cmd exits rc=0 even though the per-file copy errored (errors only on stderr).
```
- `37.hmm` is **47.8 MB**. The `checkv_hmms/` dir is **80 files, 16–48 MB each, ~2.27 GB total**.
- Source objects are intact (verified sizes via `s5cmd ls`).
- Small objects copy fine — this is **size-dependent**.

## Likely root cause
`s5cmd cp s3://src s3://dst` performs a copy that this MinIO rejects for large objects with
`IncompleteBody` (the request's body is shorter than the declared `Content-Length`). Whether
s5cmd is doing a client-side GET→PUT (truncated body) or a multipart UploadPartCopy that MinIO
mishandles, the net effect is large-object S3→S3 copies don't complete. The plugin relies on
this exact operation to stage `path` inputs into each task's `inputs/` dir.

## Suggested directions for the plugin
1. **Avoid server-side/large S3→S3 copy for stage-in.** Route large inputs through local disk:
   `s5cmd cp s3://src ./local && s5cmd cp ./local s3://taskremote/` (or stage directly to the
   task's local working dir instead of an S3 per-task `inputs/` prefix at all).
2. **Or fix the copy op**: pin/upgrade s5cmd, tune multipart copy part-size, or set MinIO
   server-side-copy limits; confirm whether `--no-verify-ssl` / proxy (traefik) truncates bodies.
3. **Surface per-file copy failures as non-zero** so the task fails fast with a clear cause
   instead of `rc=0` + a later "missing input" 404.
4. **Big reference DBs (CheckV 2.3 GB, VirSorter2 13 GB) per task is expensive anyway** — consider
   a shared host-volume / read-only mount for reference DBs instead of per-task S3 staging.

## Related second bug (already worked around in the pipeline, but worth fixing in the plugin)
The EXIT-trap **push-back** uses `s5cmd cp ./ "$NXF_S5CMD_REMOTE_WORKDIR"`. When a task's workdir
contains a **large/partly-transient sub-directory** (mmseqs `${prefix}_tmp/`, thousands of files),
the push returns **rc=0 but silently fails to propagate** `versions.yml` (and the `_tmp` dir) to S3
— Nextflow then 404s on the declared `versions.yml` output. Proven by listing the per-task remote:
every entry up to `*_rep_seq.fasta` present; `_tmp/` and `versions.yml` absent; `versions.yml`
existed locally (66 B) at trap time. Worked around in everest by `rm -rf ${prefix}_tmp` before the
task ends, but the recursive push-back being lossy (and returning rc=0) is a plugin bug.

Path scheme reference: per-task remote `s3://su-everest-nf/user/<2c>/<hash>/` (+ `inputs/`);
Nextflow workdir `s3://su-everest-nf/user/patricia/workdir/patricia-<runid>/<hash>/`.
