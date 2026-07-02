process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'

    conda { params.conda_python3_env ?: "conda-forge::python=3.8.3" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(samplesheet)

    output:
    path '*.csv'       , emit: csv
    tuple val("${task.process}"), val('python'), eval('python --version | sed "s/Python //g"'), emit: versions_python, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/everest/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv
    """

    stub:
    """
    touch samplesheet.valid.csv
    """
}
