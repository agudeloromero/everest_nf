process VIRSORTER_DETECT {
    tag "$meta.id"
    label 'process_high'

    conda { params.conda_virsorter2_env ?: "${projectDir}/envs/virsorter2.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://ghcr.io/abhi18av/everest-virsorter:2.2.4-1' :
        'ghcr.io/abhi18av/everest-virsorter:2.2.4-1' }"


    input:
    tuple val(meta), path(filtered_fasta)
    path(virsorter_db)

    output:
    tuple val(meta), path("${meta.id}")                                , emit: dir
    tuple val(meta), path("**/final-viral-combined.fa")                , emit: combined
    tuple val(meta), path("**/final-viral-score.tsv")                  , emit: score
    tuple val(meta), path("**/final-viral-boundary.tsv")               , emit: boundary
    path "versions.yml"                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: "--keep-original-seq --include-groups dsDNAphage,NCLDV,RNA,ssDNA --min-length 5000 --min-score 0.5  all"
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    virsorter run --use-conda-off  \\
        -j ${task.cpus} \\
        $args \\
        -i ${filtered_fasta} \\
        -w ${meta.id} \\
        --db-dir ${virsorter_db} \\
        2> ${prefix}_virsorter_detect.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        virsorter2: \$(echo \$(virsorter --version 2>&1) | head -n 1 | sed 's/.*VirSorter //;')
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
