process PIGZ {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*.fastq.gz')	                  , emit: fastqgz
        path "versions.yml"			                              , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -p ${task.cpus} -5 "

                                       
        """
            pigz $args $reads

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def output = meta.single_end ? 
                        "${prefix}_unmapped_R1.fastq.gz" 
                        : "${prefix}_unmapped_cat_R1.fastq.gz ${prefix}_unmapped_cat_R2.fastq.gz"

        """
            touch ${output}

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
            END_VERSIONS
        """

}

