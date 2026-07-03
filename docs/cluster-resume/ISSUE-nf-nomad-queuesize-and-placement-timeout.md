# nf-nomad: `executor.queueSize` not honored + placement-deadline fails queued tasks

## Summary
On a small abc-cluster (seedling: 3 compute nodes, only 2 usable for heavy tasks —
nomad02 24 GB, nomad03 20 GB; nomad01 8 GB), a fan-out stage (per-sample taxonomy +
cleaning-contigs, ~12–16 GB/task) submits far more tasks than the cluster can place at
once. Two coupled nf-nomad behaviours turn this into pipeline failures:

1. **`executor.queueSize` does not throttle nf-nomad submission.** Nextflow's standard
   concurrency lever has no effect — nf-nomad submits every ready task to Nomad as a job
   immediately; Nomad queues them.
2. **A ~5–6 min placement deadline fails queued tasks.** A Nomad job that can't be placed
   within the deadline is reported as `failed placement` and the Nextflow task FAILS
   (counting against `maxRetries`). On a contended cluster this exhausts retries and goes
   fatal — even though the task would place fine a minute later as capacity frees up.

Net effect: the pipeline cannot be run reliably on a small/contended cluster, and the
user has no working knob to reduce in-flight concurrency.

## Evidence (live run, `executor.queueSize = 2` set in user `-c` config)
Child Nomad task-jobs by status, mid-run:
```
    100 dead
      5 dead(stopped)
     19 pending      <-- 19 jobs queued, unplaceable
      2 running
```
=> **21 jobs in flight with queueSize=2**, so queueSize is clearly not capping submission.

Placement failure (repeats; counter climbed 5 → 28 over the stage):
```
WARN: [NOMAD] Job <run>-<hash>-TKI_EVEREST_NF_CLEANING_CONTIGS_WF_BACPHLIP_LIFE_STYLE
appears to have failed placement (no allocations after 360653ms).
This may indicate insufficient resources on available nodes.
```
(~360 s deadline; earlier instances showed ~313 s.)

The rendered head-job config (`local/nextflow.headjob.config`) contains **two**
`executor{}` blocks — abc injects one, the user `-c` adds another:
```
executor = "nomad"
executor { queueSize = 50 }          # abc-injected
...
executor { queueSize = 2 }           # user -c (docs/.../seedling.config)
```
Whichever wins, the observed in-flight count (21) matches neither 2 nor a working
throttle — consistent with nf-nomad not consuming `queueSize` for submission gating at all.

Earlier data points (same pipeline/stage): queueSize 5 → 23 placement failures (fatal),
queueSize 3 → 28 (fatal on SEQKIT_FILTER), queueSize 2 → 28 (still climbing). Lowering
`queueSize` did not materially change concurrency — further evidence it's ignored.

## What we expected vs. got
- Expected: `executor.queueSize = N` ⇒ at most N tasks submitted/running at once (as with
  the grid executors), so a small cluster drains a deep queue safely.
- Got: all ready tasks submitted to Nomad immediately; Nomad holds 19+ pending; the
  placement deadline then fails the ones that wait too long.

## Asks for nf-nomad
1. **Honor `executor.queueSize`** (or add an nf-nomad-specific equivalent, e.g.
   `nomad.maxConcurrentTasks`) so the plugin caps how many task-jobs are submitted/in
   flight at once. This is the clean fix — it lets a small cluster process a deep DAG.
2. **Make the placement deadline configurable and default to "wait, don't fail."** A queued
   Nomad job should be allowed to wait for capacity (ideally unbounded, or a large
   configurable timeout) rather than being declared `failed placement` after ~5 min.
3. **Don't count placement-timeout failures against `maxRetries`.** If a task never got an
   allocation (no exit code, purely a scheduling wait), re-queue it without consuming a
   retry, so transient saturation never goes fatal.
4. **Clarify the abc-injected `executor { queueSize = 50 }`** — does it override the user's
   `-c` value? If the plugin starts honoring queueSize, ensure user `-c` can lower it.

## Workarounds tried (pipeline/config side, all insufficient)
- `executor.queueSize` 5→3→2: did not reliably bound concurrency; placement failures
  persisted and went fatal at 5 and 3.
- The pipeline itself + the (separately fixed) dev nf-nomad-s5cmd staging are validated:
  with the dev plugin, IncompleteBody=0 and the FASTQC `Invalid prefix or suffix` are gone,
  and the pipeline runs correctly through assembly → mmseqs → CheckV → taxonomy. The ONLY
  remaining blocker to a clean end-to-end run on this small cluster is the placement /
  queueSize behaviour above.

Cluster: seedling-prod, namespace su-everest-nf. Nomad nodes: nomad01 8c/7.9 GB,
nomad02 24c/24 GB, nomad03 16c/20 GB (mnemosyne data node down). NXF_VER=26.04.0.
See also docs/cluster-resume/ISSUE-nf-nomad-s5cmd-large-object-staging.md (the staging
bug, fixed in the dev plugin).
