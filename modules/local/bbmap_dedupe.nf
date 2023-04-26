process BBMAP_DEDUPE {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

    /* container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? */
    /*         'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0': */
    /*         'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }" */


    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_dedup.fastq.gz")                   , emit: deduped_fastqgz
    tuple val(meta), path("*_cat_dedup.fastq.gz")               , emit: cat_deduped_fastqgz, optional: true
    tuple val(meta), path("*bbmap_dedupe.out")                  , emit: log

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: " -Xmx${task.memory.toMega()}m ac=f s=5 e=5 minidentity=95 "

    def input = meta.single_end ? 
                "in=${reads[0]}"
                : "in1=${reads[0]} in2=${reads[1]}" 

    def output = meta.single_end ? 
                "${prefix}_unmapped_dedup.fastq.gz" 
                : "${prefix}_unmapped_cat_dedup.fastq.gz" 

    """
    dedupe.sh ${args} ${input} out=${output} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def output = meta.single_end ? 
                "${prefix}_unmapped_dedup.fastq.gz" 
                : "${prefix}_unmapped_cat_dedup.fastq.gz" 

    """
    touch ${output}
    touch ${prefix}.bbmap_dedupe.out 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """

}
