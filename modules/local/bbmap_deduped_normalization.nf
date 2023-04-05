process BBMAP_DUDUPED_NORMALIZATION {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::bbmap=38.96' : null)

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        tuple val(meta), path(dedupe_ref)

        output:
        tuple val(meta), path('*_unmapped_cat_dedup_norm_R*.fastq.gz')		, emit: norm_fastqgz
        tuple val(meta), path('*bbmap_duduped_normalization.log')		      , emit: log
        path "versions.yml"							                                  , emit: versions

        script:
        def args = task.ext.args ?: '-Xmx20000m'
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        bbnorm.sh \\
          $args \\
            in=$f1 in2=$f2 \\
            out=${prefix}_unmapped_cat_dedup_norm_R1.fastq.gz out2=${prefix}_unmapped_cat_dedup_norm_R2.fastq.gz \\
          > ${prefix}.bbmap_duduped_normalization.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          bbnorm.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        touch ${prefix}_unmapped_cat_dedup_norm_R1.fastq.gz
        touch ${prefix}_unmapped_cat_dedup_norm_R2.fastq.gz
        touch ${prefix}.bbmap_duduped_normalization.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          bbnorm.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}

