process SPADES_DENOVO {
    tag "$meta.id"
    label 'process_high'

    conda { params.conda_spades_env ?: "${projectDir}/envs/spades.yml" }


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/spades:3.13.2--h2d02072_0' :
        'biocontainers/spades:3.13.2--h2d02072_0' }"



    input:
    tuple val(meta), path(forward_read), path(paired), path(unpaired)

    output:
    tuple val(meta), path('scaffolds.fasta')                         , optional:true, emit: scaffolds
    tuple val(meta), path('assembly_graph_with_scaffolds.gfa')       , optional:true, emit: scaffolds_graph
    tuple val(meta), path('*.log')                                   , emit: log
    path  "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--only-assembler'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxmem = task.memory.toGiga()

    def input = meta.single_end ?
                "--s1 ${forward_read}"
                : "--merge ${forward_read} -1 ${paired[0]} -2 ${paired[1]} -s ${unpaired[0]} -s ${unpaired[1]}"

    def mode = meta.single_end ? "--careful" : "--meta"

    """
    spades.py \\
        $mode \\
        $args \\
        --threads ${task.cpus} \\
        --memory $maxmem \\
        $input \\
        -o ./

    mv spades.log ${prefix}.spades.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.scaffolds.fasta
    touch ${prefix}.spades.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//')
    END_VERSIONS
    """
}
