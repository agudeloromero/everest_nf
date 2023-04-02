process CAT_PE {
        tag "$meta.id"
        label 'process_medium'

//       conda (params.enable_conda ? 'bioconda::bbmap=38.96' : null)

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(unmapped_pair)
        tuple val(meta), path(u_single_pair)

        output:
        tuple val(meta), path('*_unmapped_cat_R*.fastq')	                    , emit: reformat
        tuple val(meta), path('*S3P4_CAT_PE.log')	                            , emit: log
        path "versions.yml"			                                    , emit: versions
        tuple val(meta), path(reads)

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
          (cat $up1 $us1 > ${prefix}_unmapped_singletons_R1.fastq ; \\
            cat $up2 $us2 > ${prefix}_unmapped_singletons_R2.fastq ) \\
                  > ${prefix}.S3P4_CAT_PE.log

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    CAT_pair_unpair: \$(cat --version)
            END_VERSIONS
        """
}

