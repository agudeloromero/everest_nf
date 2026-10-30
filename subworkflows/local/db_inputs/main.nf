/*
 * Reference-database inputs: staged (default) or read in place from a worker-local mount.
 *
 * Staging a multi-GB database as a `path` input is expensive on executors that copy inputs
 * (e.g. nf-nomad-s5cmd with an S3 workdir stages each `path` head-side, then pushes the
 * task directory back). With `--db_mounted_dir <dir>` the database is instead read in place
 * from <dir>, which must be visible on every worker (a shared filesystem, or a host volume
 * such as /nxf-work/db/everest on the seedling cluster).
 *
 * Layout under <dir> mirrors the database parameter: the part after `db_dir/everest/`
 * (e.g. s3://bkt/shared/everest/db_dir/everest/DB_checkv/checkv-db-v1.1 ->
 * <dir>/DB_checkv/checkv-db-v1.1); without that marker, the last path element.
 *
 * Modules take both `path(db)` and `val(db_mounted)`; exactly one is populated.
 */

def dbStaged(String db) {
    // empty list = no staged file (optional path input)
    return params.db_mounted_dir ? [] : db
}

def dbMounted(String db) {
    if( !params.db_mounted_dir )
        return ''
    final marker = 'db_dir/everest/'
    final idx = db.indexOf(marker)
    final rel = idx >= 0 ? db.substring(idx + marker.length()) : db.tokenize('/').last()
    return "${params.db_mounted_dir.toString().replaceAll('/+$', '')}/${rel.replaceAll('/+$', '')}".toString()
}
