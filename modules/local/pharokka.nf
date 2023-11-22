process PHAROKKA {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_pharokka_env ?: "${projectDir}/envs/pharokka.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/pharokka:1.3.2--hdfd78af_0':
           'quay.io/biocontainers/pharokka:1.3.2--hdfd78af_0' }"


        input:
        tuple val(meta), path(fasta)

        output:
        tuple val(meta), path("${meta.id}")	                  , emit: fastqgz
        path "versions.yml"			                          , emit: versions

        script:
        prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -p  "

        """
            pharokka.py -i ${fasta} -o ${prefix} -t ${task.cpus} -d ${params.pharokka_db}


            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    pharokka: 1.3.2
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

