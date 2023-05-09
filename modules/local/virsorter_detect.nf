process VIRSORTER_DETECT {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_virsorter_env ?: "${projectDir}/envs/virsorter.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0' :
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(filtered_fasta)
    path(virsorter_db)

    output:
    tuple val(meta), path("${meta.id}")                        , emit: dir
    tuple val(meta), path("**/final-viral-combined.fa")        , emit: viral
    tuple val(meta), path("**/final-viral-score.tsv")          , emit: score
    tuple val(meta), path("**/final-viral-boundary.tsv")       , emit: boundary
    path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: "--keep-original-seq --include-groups dsDNAphage,NCLDV,RNA,ssDNA --min-length 5000 --min-score 0.5 -j $task.cpus all"
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    virsorter run \\
        $args \\
        -i ${filtered_fasta} \\
        -w ${meta.id} \\
        --db-dir ${virsorter_db} \\
        2> ${prefix}_virsorter_detect.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_virsorter_detect.log

    mkdir $prefix
    touch $prefix/final-viral-combined.fa
    touch $prefix/final-viral-score.tsv
    touch $prefix/final-viral-boundary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """



}
