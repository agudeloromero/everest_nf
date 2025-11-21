process RENEO {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_reneo_env ?: "${projectDir}/envs/reneo.yml" }

    //FIXME with a custom container with both gurobi and reneo. Also add
    //instructions about databases
    /*
        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/reneo:0.2.0--pyhdfd78af_0':
           'quay.io/biocontainers/reneo:0.2.0--pyhdfd78af_0' }"
     */


        input:
        tuple val(meta), path(scaffolds_graph), path("fastq/*")

        output:
        tuple val(meta), path("${meta.id}")                   , emit: fastqgz
        path "versions.yml"                                   , emit: versions

        script:
        prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -p  "

        """
            reneo run --input ${scaffolds_graph} --reads fastq/ --threads ${task.cpus} --databases ${params.reneo_db}

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    reneo: \$( reneo --version 2>&1 | sed 's/reneo //g' )
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            mkdir ${prefix}

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    reneo: \$( reneo --version 2>&1 | sed 's/reneo //g' )
            END_VERSIONS
        """

}
