process BBMAP_REFORMAT {
        tag "$meta.id"
        label 'process_medium'

        conda "${projectDir}/envs/BBMAP.yml"

        container "${}${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        tuple val(meta), path(unmapped_single)

        output:
        tuple val(meta), path('*_unmapped_singletons_R*.fastq')	                , emit: singleton_pair
        tuple val(meta), path('*bbmap_singletons.log')			                    , emit: log
        path "versions.yml"							                                        , emit: versions

        script:
        def args = task.ext.args ?: '-Xmx20000m'
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        reformat.sh \\
          $args \\
          in1=$unmapped_single \\
          out=${prefix}_unmapped_singletons_R1.fastq out2=${prefix}_unmapped_singletons_R2.fastq  \\
          > ${prefix}.bbmap_singletons.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            reformat.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        touch ${prefix}_unmapped_singletons_R1.fastq 
        touch ${prefix}_unmapped_singletons_R2.fastq 
        touch ${prefix}.bbmap_singletons.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            reformat.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}

