process MINIMAP2_INDEX {
    label 'process_medium'

    // Note: the versions here need to match the versions used in minimap2/align
    conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/minimap2:2.24--h7132678_1' :
        'quay.io/biocontainers/minimap2:2.24--h7132678_1' }"

    input:
    path(fasta)

    output:
    path("*.mmi")                 , emit: index
    tuple val("${task.process}"), val('minimap2'), eval('minimap2 --version 2>&1'), emit: versions_minimap2, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    minimap2 \\
        -t $task.cpus \\
        -d ${fasta.baseName}.mmi \\
        $args \\
        $fasta
    """

    stub:
    """
    touch ${fasta.baseName}.mmi
    """


}
