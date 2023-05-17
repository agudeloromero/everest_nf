process CHECKV_VIRAL_SEQ {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_checkv_env ?: "${projectDir}/envs/checkv.yml" }

/*
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0' :
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"
*/
    input:
    tuple val(meta), path(fasta)
    path(checkv_db)

    output:
    tuple val(meta), path("**/viruses.fna")                           , emit: fasta
    tuple val(meta), path("viruses_renamed.fasta")                    , emit: renamed_fasta
    path "versions.yml"                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: "-t $task.cpus"
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    checkv end_to_end \\
        $args \\
        -d ${checkv_db} \\
        ${fasta} \\
        ${prefix} \\
        2> ${prefix}_checkv_viral_seq.log

    sed 's/||.*//' ${prefix}/viruses.fna > viruses_renamed.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: \$(echo \$(checkv --version 2>&1))
    END_VERSIONS
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_viruses_renamed.fasta
    touch ${prefix}_checkv_viral_seq.log

    mkdir $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: \$(echo \$(checkv --version 2>&1))
    END_VERSIONS
    """



}
