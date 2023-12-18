process BBMAP_DUDUPED_NORMALIZATION {
        tag "$meta.id"
        label 'process_high'

        conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0':
            'biocontainers/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0' }"

        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*_dedup_norm_R*.fastq.gz')		              , emit: norm_fastqgz
        tuple val(meta), path('*bbmap_duduped_normalization.log')		      , emit: log
        path "versions.yml"							                          , emit: versions

        script:
        def args = task.ext.args ?: ""
        def prefix = task.ext.prefix ?: "${meta.id}"

        def input = meta.single_end ?
                    "in=${reads}}"
                    : "in=${reads[0]} in2=${reads[1]}"

        def output = meta.single_end ?
                     "out=${prefix}_unmapped_dedup_norm_R1.fastq.gz"
                    : "out=${prefix}_unmapped_cat_dedup_norm_R1.fastq.gz out2=${prefix}_unmapped_cat_dedup_norm_R2.fastq.gz"

        """
        bbnorm.sh \\
          -Xmx${task.memory.toMega()}m \\
          $args \\
          tmpdir=tmp \\
          $input\\
          $output \\
          2> ${prefix}.bbmap_duduped_normalization.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          bbnorm.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        def output = meta.single_end ?
                     "${prefix}_unmapped_dedup_norm_R1.fastq.gz"
                    : "${prefix}_unmapped_cat_dedup_norm_R1.fastq.gz ${prefix}_unmapped_cat_dedup_norm_R2.fastq.gz"


        """
        touch ${output}
        touch ${prefix}.bbmap_duduped_normalization.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          bbnorm.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}

