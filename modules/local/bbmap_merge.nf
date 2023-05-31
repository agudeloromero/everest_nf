process BBMAP_MERGE {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_unmapped_cat_unmerge_R*.fastq.gz")             , emit: unmerged
    tuple val(meta), path("*_unmapped_cat_R1_merge.fastq.gz")               , emit: merged
    tuple val(meta), path("*.bbmap_merge.log")                              , emit: log
    path "versions.yml"							                            , emit: versions

    script:
    def args = task.ext.args ?: "-Xmx${task.memory.toMega()}m"
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bbmerge.sh ${args} \\
        in1=${reads[0]} \\
        in2=${reads[1]} \\
        out=${prefix}_unmapped_cat_R1_merge.fastq.gz \\
        outu1=${prefix}_unmapped_cat_unmerge_R1.fastq.gz \\
        outu2=${prefix}_unmapped_cat_unmerge_R2.fastq.gz  \\
        2> ${prefix}.bbmap_merge.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '-Xmx20000m'

    """
    touch ${prefix}_unmapped_cat_R1_merge.fastq.gz
    touch ${prefix}_unmapped_cat_unmerge_R1.fastq.gz
    touch ${prefix}_unmapped_cat_unmerge_R2.fastq.gz
    touch ${prefix}.bbmap_merge.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_MERGE: \$(bbmap --version)
    END_VERSIONS
    """

}
