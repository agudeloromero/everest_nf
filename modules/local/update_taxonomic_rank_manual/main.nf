process UPDATE_TAXONOMIC_RANK_MANUAL {
    tag "${task.ext.prefix ?: 'update_taxonomic_rank_manual'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/pandas:1.5.2' :
        'quay.io/biocontainers/pandas:1.5.2' }"

    input:
    path(summary_files)

    output:
    path("*_stats_taxrank.txt") , emit: taxrank_files
    tuple val("${task.process}"), val('python'), eval('python --version 2>&1 | sed "s/Python //"'), emit: versions_python, topic: versions

    script:
    """
    update_taxonomic_rank_manual.py .
    """

    stub:
    """
    touch test_nt_summary_mmseqs2_stats_taxrank.txt
    touch test_aa_summary_mmseqs2_stats_taxrank.txt
    """
}