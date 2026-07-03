process KALLISTO_INDEX {
    tag "$fasta"
    label 'process_medium'

    conda "bioconda::kallisto=0.46.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kallisto:0.46.2--h4f7b962_1' :
        'quay.io/biocontainers/kallisto:0.46.2--h4f7b962_1' }"

    input:
    path fasta

    output:
    path "kallisto" , emit: idx
    tuple val("${task.process}"), val('kallisto'), eval('kallisto 2>&1 | head -1 | sed "s/^kallisto //"'), emit: versions_kallisto, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    kallisto \\
        index \\
        $args \\
        -i kallisto \\
        $fasta
    """

    stub:
    """
    touch kallisto
    """
}
