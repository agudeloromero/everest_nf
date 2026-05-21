process BBMAP_PROCESS {
    tag "${task.ext.prefix ?: 'bbmap_process'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://python:3.11-slim' :
        'python:3.11-slim' }"

    input:
    path(bbmap_input_files)

    output:
    path("*_bbmap_stats.txt")      , emit: bbmap_stats
    path("versions.yml")           , emit: versions

    script:
    """
    bbmap_process.py .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    touch test_bbmap_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """
}