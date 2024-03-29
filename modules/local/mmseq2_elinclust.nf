process MMSEQ2_ELINCLUST {
    tag "$meta.id"
    label 'process_high'

    conda { params.conda_mmseqs2_env ?: "${projectDir}/envs/MMSEQS.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
         'https://depot.galaxyproject.org/singularity/mmseqs2:14.7e284--pl5321hf1761c0_1' :
         'quay.io/biocontainers/mmseqs2:14.7e284--pl5321hf1761c0_1' }"


    input:
    tuple val(meta), path(scaffolds)

    output:
    tuple val(meta), path("*_all_seqs.fasta")                                                       , emit: all_seqs
    tuple val(meta), path("*_cluster.tsv")                                                          , emit: cluster
    tuple val(meta), path("*_rep_seq.fasta")                                                        , emit: rep_seq
    tuple val(meta), path("*_all_seqs.fasta"), path("*_cluster.tsv"), path("*_rep_seq.fasta")       , emit: all
    tuple val(meta), path('*.log')                                                                  , emit: log
    path  "versions.yml"                                                                            , emit: versions

    script:
    def args = task.ext.args ?: " --min-seq-id 0.98 --kmer-per-seq-scale 0.3 --sort-results 1 --alignment-mode 3 --cov-mode 1"
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mmseqs easy-linclust \\
        --threads ${task.cpus} \\
        ${scaffolds} \\
        ${prefix} \\
        ${prefix}_tmp \\
        ${args} \\
        2> ${prefix}.mmseqs_linclust.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs --help | grep 'MMseqs2 Version' | sed 's/^MMseqs2 Version: //; s/\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_all_seqs.fasta
    touch ${prefix}_cluster.tsv
    touch ${prefix}_rep_seq.fasta
    touch ${prefix}.mmseqs_linclust.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs --help | grep 'MMseqs2 Version' | sed 's/^MMseqs2 Version: //; s/\$//')
    END_VERSIONS
    """
}
