process BBMAP_REFORMAT {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::bbmap=38.96' : null)

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        tuple val(meta), path(unmapped_single)

        output:
        tuple val(meta), path('*_unmapped_singletons_R*.fastq')	                , emit: u_single_pair
        tuple val(meta), path('*S3P3_BBMAP_singletons_PE.log')			, emit: log
        path "versions.yml"							, emit: versions

        script:
        def args = task.ext.args ?: '-Xmx20000m'
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        reformat.sh \\
          $args \\
          in1=$s1 \\
          out=${prefix}_unmapped_singletons_R1.fastq out2=${prefix}_unmapped_singletons_R2.fastq  \\
          > ${prefix}.S3P3_BBMAP_singletons_PE.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          reformat.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}

