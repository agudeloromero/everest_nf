process RENEO {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_reneo_env ?: "${projectDir}/envs/reneo.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/reneo:1.3.2--hdfd78af_0':
           'quay.io/biocontainers/reneo:1.3.2--hdfd78af_0' }"


        input:
        tuple val(meta), path(fasta)

        output:
        tuple val(meta), path("${meta.id}")	                  , emit: fastqgz
        path "versions.yml"			                          , emit: versions

        script:
        prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -p  "

        """
            reneo run --input assembly_graph.gfa --reads fastq/ --threads 8

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    reneo: FIXME
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            mkdir ${prefix}

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    reneo: FIXME
            END_VERSIONS
        """

}

