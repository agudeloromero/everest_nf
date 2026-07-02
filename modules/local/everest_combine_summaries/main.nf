process EVEREST_COMBINE_SUMMARIES {
    tag "${task.ext.prefix ?: 'everest_combine_summaries'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/pandas:1.5.2' :
        'quay.io/biocontainers/pandas:1.5.2' }"

    input:
    path(taxrank_files)

    output:
    path("EVEREST_nt_summary.txt") , emit: nt_summary
    path("EVEREST_aa_summary.txt") , emit: aa_summary
    tuple val("${task.process}"), val('python'), eval('python --version 2>&1 | sed "s/Python //"'), emit: versions_python, topic: versions

    script:
    """
    everest_combine_summaries.py .
    """

    stub:
    """
    touch EVEREST_nt_summary.txt
    touch EVEREST_aa_summary.txt
    """
}