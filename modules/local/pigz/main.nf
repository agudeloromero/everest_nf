process PIGZ {
        tag "$meta.id"
        label 'process_medium'
        stageInMode "copy"


        //NOTE: Use minimap2 as a proxy for pigz
        conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/pigz:2.8':
            'biocontainers/pigz:2.8' }"

        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*.fastq.gz')	                  , emit: fastqgz
        tuple val("${task.process}"), val('pigz'), eval('pigz --version 2>&1 | sed "s/pigz //g"'), emit: versions_pigz, topic: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: "  -5 "


        """
            pigz -p ${task.cpus} $args $reads
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def output = meta.single_end ?
                        "${prefix}_unmapped_R1.fastq.gz"
                        : "${prefix}_unmapped_cat_R1.fastq.gz ${prefix}_unmapped_cat_R2.fastq.gz"

        """
            touch ${output}
        """

}

