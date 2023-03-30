process S3P5_PIGZ_fastq {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::pigz=2.6' : null)

  //      container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
  //          'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
  //          'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(reformat)

        output:
        tuple val(meta), path('*_unmapped_cat_R*.fastq.gz')			, emit: reformat_gz
        tuple val(meta), path('*S3P5_PIGZ_fastq.log')				, emit: log
        path "versions.yml"							, emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        ( pigz $args $r1 ; \\
              pigz $args $r2 ) \\
              > ${prefix}.S3P5_PIGZ_fastq.log

        pigz <<-END_VERSIONS > versions.yml
        "${task.process}":
          pigz: \$(pigz)
        END_VERSIONS
        """
}

