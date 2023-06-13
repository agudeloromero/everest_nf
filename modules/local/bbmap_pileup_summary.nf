process BBMAP_PILEUP_SUMMARY {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

    /* container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? */
    /*         'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0': */
    /*         'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }" */


    input:
    tuple val(meta), path(contigs), path(sam)

    output:
    tuple val(meta), path("*_contig_rpkm.txt")           , emit: rpkm
    tuple val(meta), path("*_contig_stats.txt")          , emit: stats
    tuple val(meta), path("*_contig_normcov.txt")        , emit: normcov
    path "versions.yml"                                  , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: " "

    """
    bbmap.sh \\
        -Xmx${task.memory.toMega()}m \\
        threads=${task.cpus} \\
        ref=${contigs} \\
        in=${sam} \\
        out=${prefix}_contig.stats.txt \\
        rpkm=${prefix}_contig_rpkm.txt \\
        normcov=${prefix}_contig_normcov.txt \\
        ${args} \\
    2> ${prefix}.bbmap_pileup_summary.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_contig.sam
    touch ${prefix}_contig_rpk.txt
    touch ${prefix}_contig_scafstats.txt
    touch ${prefix}_contig_covstats.txt

    touch ${prefix}.bbmap_pileup_summary.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dedupe.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """

}
