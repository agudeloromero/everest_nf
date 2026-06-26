process SEQKIT_FILTER {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_seqkit_env ?: "${projectDir}/envs/seqkit.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0' :
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_rep_seq_FilterLen.fasta"), emit: filtered_fasta
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: "-m 5000 "
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    seqkit seq \\
        --threads $task.cpus \\
        $args \\
        $fasta \\
        -o ${prefix}_rep_seq_FilterLen.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_rep_seq_FilterLen.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """

}
