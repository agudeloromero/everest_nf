process BBMAP_DEDUPE {
    tag "$meta.id"
    label 'process_medium'

    conda "envs/BBMAP.yml"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_unmapped_cat_dedup.fastq.gz")             , emit: deduped_fastqgz
    tuple val(meta), path("*bbmap_dedupe.out")                         , emit: log

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    dedupe.sh ${task.memory} ${args} in1=${reads{0}} in2=${reads{1}} out=${prefix}.bbmap_dedupe.out 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_unmapped_cat_dedup.fastq.gz
    touch ${prefix}.bbmap_dedupe.out 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """

}
