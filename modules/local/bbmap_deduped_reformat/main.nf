process BBMAP_DEDUPED_REFORMAT {
        tag "$meta.id"
        label 'process_medium'
        label 'error_retry'

        conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
             'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
             'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(cat_deduped_fastqgz)

        output:
        tuple val(meta), path('*_unmapped_cat_dedup_R*.fastq.gz')		, emit: reformatted_fastq
        tuple val(meta), path('*bbmap_deduped_reformat.log') 		    , emit: log
        tuple val("${task.process}"), val('reformat.sh'), eval('bbversion.sh | grep -v "Duplicate cpuset"'), emit: versions_reformat, topic: versions

        script:
        def args = task.ext.args ?: ""
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        reformat.sh \\
          -Xmx${task.memory.toMega()}m \\
          $args \\
          in=$cat_deduped_fastqgz \\
          out=${prefix}_unmapped_cat_dedup_R1.fastq.gz \\
          out2=${prefix}_unmapped_cat_dedup_R2.fastq.gz \\
        2> ${prefix}.bbmap_deduped_reformat.log
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        touch ${prefix}_unmapped_cat_dedup_R1.fastq.gz
        touch ${prefix}_unmapped_cat_dedup_R2.fastq.gz
        touch ${prefix}.bbmap_deduped_reformat.log

        """


}

