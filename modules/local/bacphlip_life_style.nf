process BACPHLIP_LIFE_STYLE {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_bacphlip_env ?: "${projectDir}/envs/bacphlip.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-e16bfb0f667f2f3c236b32087aaf8c76a0cd2864:c64689d7d5c51670ff5841ec4af982edbe7aa406-0':
        'biocontainers/mulled-v2-e16bfb0f667f2f3c236b32087aaf8c76a0cd2864:c64689d7d5c51670ff5841ec4af982edbe7aa406-0' }"


    input:
    tuple val(meta), path(renamed_fasta)

    output:
    tuple val(meta), path("viruses_renamed.fasta.bacphlip")                   , emit: fasta_bacphlip
    path "versions.yml"                                                       , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def args = task.ext.args ?: "-f "


    """

    if [ "\$(cat viruses_renamed.fasta  | grep '>' | wc -l )" -lt 2 ];
        then echo "NOT multifasta" && bacphlip -i ${renamed_fasta} ${args} ;
        else echo "YES multifasta" && bacphlip -i ${renamed_fasta} ${args} --multi_fasta ;
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bacphlip: 0.9.6
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch viruses_rename.fasta.bacphlip

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bacphlip: 0.9.6
    END_VERSIONS
    """

}
