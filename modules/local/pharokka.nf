process PHAROKKA {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_pharokka_env ?: "${projectDir}/envs/pharokka.yml" }

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(fasta)

        output:
        tuple val(meta), path('*.fastq.gz')	                  , emit: fastqgz
        path "versions.yml"			                          , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -p  "

        """
            pharokka.py -i ${fasta} -o ${prefix} -t ${task.cpus} -d ${params.pharokka_db}


            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    pharokka: FIXME
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            mkdir ${prefix}

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    pharokka: FIXME
            END_VERSIONS
        """

}

