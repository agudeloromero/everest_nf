process BBMAP_DUDUPED_NORMALIZATION {
        tag "$meta.id"
        label 'process_medium'

        conda "${projectDir}/envs/BBMAP.yml"

        /* container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? */
        /*     'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0': */
        /*     'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }" */

        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*_dedup_norm_R*.fastq.gz')		              , emit: norm_fastqgz
        tuple val(meta), path('*bbmap_duduped_normalization.log')		      , emit: log
        path "versions.yml"							                                  , emit: versions

        script:
        def args = task.ext.args ?: "-Xmx${task.memory}m"
        def prefix = task.ext.prefix ?: "${meta.id}"

        def input = meta.single_end ?
                    "in=${reads}}" 
                    : "in=${reads[0]} in2=${reads[1]}"

        def output = meta.single_end ?
                     "out=${prefix}_unmapped_dedup_norm_R1.fastq.gz" 
                    : "out=${prefix}_unmapped_cat_dedup_norm_R1.fastq.gz out2=${prefix}_unmapped_cat_dedup_norm_R2.fastq.gz"

        """
        bbnorm.sh \\
          $args \\
          $input\\
          $output \\ 
          > ${prefix}.bbmap_duduped_normalization.log

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

