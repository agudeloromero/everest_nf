# OCI resources — transition / decommission plan

Plan to wind down the OCI footprint (`oci-aus` = `tki-aerial-ol8`, Sydney) now that
EVEREST is consolidated on acacia (`tki-acacia:pub-everest`, 1.05 TiB, verified).
Goal: retire OCI compute + block volumes + object storage **without losing anything**,
and keep EVEREST work runnable on abc-cluster/seedling throughout.

Status date: 2026-06-18.

---

## 1. Current OCI inventory

### Compute
- **Instance `tki-aerial-ol8`** (OCI ap-sydney-1, user `opc`) — analysis box + rclone relay.
  - root `/dev/mapper/ocivolume-root` 9.8 T (2.8 T used)
  - `/dev/sdb` 984 G → `data/data-everest-1tb-01` (102 G used) — **redundant** everest workspace (its `data_test` = 0-diff subset of main; rest `_deleteme`)
  - `/dev/sdc` 2.0 T → `data/data-xdr-2tb-01` (1020 G used) — **XDR project data (non-everest)**

### Object storage (`oci-s3-phd-au`)
| Bucket | Size | Objects | Contents | Disposition |
|---|---|---|---|---|
| `everest` | 79.3 GiB | 44,419 | `db_dir/everest` (33 G DBs), `data_test`, `_configs`, `_samplesheets` | **KEEP** (canonical everest backup + seedling staging source) |
| `aerial` | **1.775 TiB** | 203,037 | mixed: everest runs + mag/taxprofiler/detaxizer runs + `setonix-everest-32577` + `genome.fa` | **CLASSIFY → migrate/delete** |

### On-server data still resident (~3.7 T home)
- EVEREST footprint (`EVEREST/`, `db_dir/everest`, `dataset/*`) — ✅ backed up (acacia + OCI everest bucket)
- **Non-EVEREST** (needs owner sign-off / backup before wipe): `data/data-xdr-2tb-01` (1 T), `results/detaxizer` (910 G), `results/mag` (115 G), `results/taxprofiler` (26 G), other `db_dir` DBs (CAT/GTDB/Kraken2/Centrifuge/CheckM2 ~406 G), `ANALYSIS-JNN-XDR` (2 G), `magma_test` (8.5 G)

---

## 2. What is already safe (no action)
- **EVEREST** → `tki-acacia:pub-everest` (1.05 TiB, verified 0-diff) **and** `oci-s3-phd-au:everest` (79 G). Two copies, two providers.
- `setonix-everest-32577`, everest-nf PRJ*, snakemake EVEREST, DB tarballs → all in `pub-everest`.
- CAP11520 → `tki-acacia:aerial/20230227_WGS_AERIAL/CAP11520.tar`.

## 3. What is NOT yet safe (blockers to wiping)
1. **OCI `aerial` bucket (1.775 TiB)** — mixed everest/non-everest run outputs; not classified, partially redundant with acacia.
2. **Non-EVEREST server data (~2.5 T)** — XDR, detaxizer/mag/taxprofiler results, other reference DBs. Owner + backup status unknown.

---

## 4. Transition sequence (safe order)

**Phase T0 — EVEREST backups confirmed** ✅ done (acacia + OCI everest verified).

**Phase T1 — Decouple seedling from OCI**
- Decide seedling staging source: pull EVEREST DBs/test-data to seedling from **acacia `pub-everest`** (preferred — keeps OCI deletable) or from OCI `everest`.
- Once seedling has its copy (or we commit to acacia as source), the OCI `everest` bucket is no longer load-bearing for active work.

**Phase T2 — Classify & drain OCI `aerial` (1.775 TiB)**
- Inventory top-level prefixes; split everest vs non-everest.
- EVEREST bits already on acacia → verify, then delete from OCI.
- Non-everest run outputs → confirm owner wants them; if yes, copy to acacia (`aerial`/`temp`) or hand to owner; if no, delete. (`abc data`/rclone copy → verify → lazy delete, same pattern as the consolidation script.)

**Phase T3 — Handle non-EVEREST server data (~2.5 T)**
- Get sign-off from data owners (XDR, COMBAT/mag/taxprofiler).
- Back up anything to keep (acacia `temp`/owner storage); the reference DBs (CAT/GTDB/Kraken2/etc.) are re-downloadable — likely no backup needed, just note provenance.

**Phase T4 — Tear down compute + volumes**
- Snapshot `/dev/sdc` (XDR) only if owner wants a point-in-time image.
- Detach + delete block volumes `/dev/sdb` (redundant) and `/dev/sdc` (after T3).
- Terminate instance `tki-aerial-ol8` (this also drops the rclone relay — do this LAST, after all transfers).
- Remove the boot/root volume with the instance.

**Phase T5 — Object storage final state**
- `everest` bucket: **keep** as cross-provider backup (cheap at 79 G) until seedling is in steady state, then decide keep/delete.
- `aerial` bucket: delete once T2 is complete (largest ongoing cost saving).

---

## 5. Decisions needed from you
1. **OCI `everest` bucket** — keep as long-term cross-provider backup, or delete once acacia is confirmed canonical + seedling staged?
2. **OCI `aerial` bucket (1.775 TiB)** — who owns the non-everest runs, and do they need preserving (→ where) or can they be deleted?
3. **Non-EVEREST server data** — owner sign-off to delete XDR / detaxizer / mag / taxprofiler / extra DBs, or back up first (where)?
4. **Seedling staging source** — acacia `pub-everest` (lets OCI go) or OCI `everest`?
5. **Compute termination timing** — terminate `tki-aerial-ol8` now (use another host as rclone relay) or keep briefly as the relay through T2/T3?

## 6. Cost / risk notes
- OCI ongoing cost is dominated by: `aerial` bucket 1.775 TiB + ~3 T block volumes + the running instance. T2+T4+T5 remove the bulk.
- **Never delete the last copy.** Every delete in T2/T3 must follow copy → `rclone check` (0 diff) → delete (the consolidation script's model).
- The instance is the current rclone relay for both OCI and acacia remotes — terminate it **last**, or move the rclone config to another host (e.g. `sun-hemera`, which already has both remotes) before T4.
- `data-xdr-2tb-01` and the COMBAT/mag/taxprofiler results are **other people's work** — do not delete without explicit owner confirmation.
