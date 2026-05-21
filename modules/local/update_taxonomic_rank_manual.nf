process UPDATE_TAXONOMIC_RANK_MANUAL {
    tag "${task.ext.prefix ?: 'update_taxonomic_rank_manual'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://python:3.11-slim' :
        'python:3.11-slim' }"

    input:
    path(summary_files)

    output:
    path("*_stats_taxrank.txt") , emit: taxrank_files
    path("versions.yml")        , emit: versions

    script:
    """
    update_taxonomic_rank_manual.py .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    touch test_nt_summary_mmseqs2_stats_taxrank.txt
    touch test_aa_summary_mmseqs2_stats_taxrank.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """
}