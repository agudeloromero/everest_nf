process MINIMAP2_HOST_REMOVAL {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0' :
            'quay.io/biocontainers/minimap2:2.24--h7132678_1' }"

        input:
        path index
        tuple val(meta), path(fastqs)

        output:
        tuple val(meta), path('*_unmapped_R*.fastq')			        , emit: unmapped
        tuple val(meta), path('*_unmapped_singletons.fastq')            , emit: singleton, optional: true
        tuple val(meta), path('*minimap2_host_removal.log')	            , emit: log
        path "versions.yml"						                        , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args_minimap2 = task.ext.args_minimap2 ?: '-ax sr --secondary=no'
        def args_samtools_view = task.ext.args_samtools_view ?: ' -f 4 -h'
        def args_samtools_sort = task.ext.args_samtools_sort ?: " "
        def args_samtools_fastq = task.ext.args_samtools_fastq ?: " -NO "

        def output = meta.single_end ?
                    "${prefix}_unmapped_R1.fastq"
                    : "-1 ${prefix}_unmapped_R1.fastq -2 ${prefix}_unmapped_R2.fastq -s ${prefix}_unmapped_singletons.fastq"

        """
        minimap2 $args_minimap2 -t ${task.cpus} $index ${fastqs} \\
          | samtools view $args_samtools_view - \\
          | samtools sort -@ ${task.cpus} $args_samtools_sort \\
          | samtools fastq -@ ${task.cpus} $args_samtools_fastq - \\
          ${output} \\
          > ${prefix}.minimap2_host_removal.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(minimap2 --version 2>&1)
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def output = meta.single_end ?
                    "${prefix}_unmapped_R1.fastq"
                    : " ${prefix}_unmapped_R1.fastq ${prefix}_unmapped_R2.fastq ${prefix}_unmapped_singletons.fastq"


        """
        touch ${output}
        touch ${prefix}.minimap2_host_removal.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(minimap2 --version 2>&1)
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        END_VERSIONS
        """

}

