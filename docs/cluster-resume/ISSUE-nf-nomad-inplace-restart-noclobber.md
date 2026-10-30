# nf-nomad: in-place task restart reuses the work dir → retries fail (noclobber / stale outputs)

## Summary
When a Nextflow task fails its first attempt, nf-nomad lets **Nomad restart the task
in-place** (same allocation, same working directory). The re-run therefore starts in a dir
that still contains the previous attempt's partial outputs. This breaks retries two ways:

1. **Noclobber (immediate, fatal):** nf-core sets `process.shell = ['bash', '-C', …]`
   (noclobber). The task's `.command.sh` has `#!/usr/bin/env bash -C -e -u -o pipefail`.
   Most modules redirect stderr to a fixed file, e.g. `… 2> ${prefix}.mmseqs_etaxonomy_${mode}.log`.
   On the in-place restart that file already exists, so `2>` under `-C` dies with
   `cannot overwrite existing file` → exit 1 → the task fails permanently. A *transient*
   first-attempt failure (preemption, a node blip, a placement hiccup) thus becomes fatal.
2. **Stale partial outputs (latent, correctness):** even without noclobber, re-running in the
   same dir means half-written outputs and scratch trees from attempt 1 are present (e.g.
   mmseqs `${prefix}_${mode}_tmp/`), which can corrupt or confuse the retry.

This defeats Nextflow's own retry model, which assumes each retry runs in a **fresh** work dir
(new task hash) — that is why `process.shell -C` (noclobber) is safe on every other executor.

## Evidence (seedling, pipeline agudeloromero/everest_nf)
Two independent modules hit this; both succeed on a clean first attempt:

```
ERROR ~ Error executing process > 'TKI:EVEREST_NF:TAXONOMY_WF:MMSEQ2_ETAXONOMY_NT (LAMBDALR : nt)'
  [NOMAD] Task failed ... exit status 1 ... | Task restarting in 15.886693757s |
  Task started by client | Exit Code: 1 ... | Exceeded allowed attempts 1 in interval 24h0m0s and mode is "fail"
Command error:
  .command.sh: line 2: LAMBDALR.mmseqs_etaxonomy_nt.log: cannot overwrite existing file
```
```
ERROR ~ Error executing process > 'TKI:EVEREST_NF:CLEANING_CONTIGS_WF:BBMAP_MAPPING_CONTIGS (LAMBDALR)'
Command error:
  .command.sh: line 2: LAMBDALR.bbmap_mapping_contigs.out: cannot overwrite existing file
```

The Nomad **task** restart policy (from `nomad job inspect` of a spawned task job):
```json
{ "Attempts": 1, "Delay": 15000000000, "Interval": 86400000000000, "Mode": "fail" }
```
i.e. Nomad restarts the failed task **once, in the same alloc/workdir** (15s delay), then fails.
(The task-group ReschedulePolicy is also `Attempts:1`.) The `.command.sh` shebang is
`#!/usr/bin/env bash -C -e -u -o pipefail`.

In this pipeline **13 local modules** redirect stderr to `2> ${prefix}…` (bbmap_*, trimm_*,
checkv_viral_seq, mmseq2_elinclust, mmseq2_etaxonomy, summary_per_sample, virsorter_detect,
bbmap_mapping_contigs, …), so any of them inherits this failure mode on a restart.

## Root cause
nf-nomad maps a Nextflow task to a Nomad job whose **task RestartPolicy = {Attempts:1, Mode:fail}**,
so Nomad performs an **in-place restart** in the existing working directory. Nextflow, however,
owns retry semantics: with `errorStrategy 'retry'` it re-submits the task as a **new task hash in
a fresh work dir**. The Nomad-level in-place restart pre-empts/duplicates Nextflow's model and
reuses the dir, which is incompatible with `-C` noclobber and with idempotent re-execution.

## Asks for nf-nomad
1. **Set the task RestartPolicy to `Attempts = 0`** (no in-place Nomad restart). Let the task
   fail fast and let **Nextflow** handle the retry — it will create a fresh work dir, so the
   noclobber `2>` redirect and any scratch dirs are clean. This is the canonical Nextflow model
   and fixes all modules at once. (Pair with `errorStrategy`/`maxRetries` in the pipeline as usual.)
2. **If in-place restarts must stay**, have the wrapper **clean the task work dir before re-running**
   (remove the previous attempt's outputs/scratch, keep staged inputs) so the re-run is idempotent.
3. Optionally document the interaction: `process.shell` with `-C` (nf-core default since 4.0) is
   incompatible with in-place restarts; pipelines on nf-nomad otherwise have to drop `-C`.

## Pipeline-side workaround already applied (insufficient as the real fix)
- Dropped `-C` from `process.shell` in the cluster config so the `2>` redirect can overwrite on a
  restart. This unblocks runs but does **not** address the stale-partial-output correctness risk
  (#2 above) — the retry still reuses attempt 1's dir.
- Added `rm -f <stale outputs>` at the start of `bbmap_mapping_contigs` as a per-module guard;
  doing this across all 13 modules is whack-a-mole and is exactly what `Attempts:0` avoids.

## Environment
Cluster seedling-prod, namespace `su-everest-nf`; nf-nomad + nf-nomad-s5cmd (dev plugin via
`abc pipeline run --dev-plugins`); NXF_VER=26.04.0. Related nf-nomad issues already documented:
`docs/cluster-resume/ISSUE-nf-nomad-queuesize-and-placement-timeout.md` and
`docs/cluster-resume/ISSUE-nf-nomad-s5cmd-large-object-staging.md`.
