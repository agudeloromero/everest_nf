process EVEREST_COMBINE_SUMMARIES {
    tag "${task.ext.prefix ?: 'everest_combine_summaries'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://python:3.11-slim' :
        'python:3.11-slim' }"

    input:
    path(taxrank_files)

    output:
    path("EVEREST_nt_summary.txt") , emit: nt_summary
    path("EVEREST_aa_summary.txt") , emit: aa_summary
    path("versions.yml")           , emit: versions

    script:
    """
    everest_combine_summaries.py .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    touch EVEREST_nt_summary.txt
    touch EVEREST_aa_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """
}