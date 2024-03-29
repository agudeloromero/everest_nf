process SAMTOOLS_FASTQ {
        tag "$meta.id"
        label 'process_medium'

        //NOTE: Use minimap2 as a proxy for samtools
        conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
           'build_minimap2--65abc6499991bbbc.sif':
           'FIXME' }"

        input:
        tuple val(meta), path(bam)

        output:
        tuple val(meta), path('*_unmapped_R*.fastq')			        , emit: unmapped
        tuple val(meta), path('*_unmapped_singletons.fastq')            , emit: singleton, optional: true
        tuple val(meta), path('*samtools_fastq.log')	                , emit: log
        path "versions.yml"                                             , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args_samtools_view = task.ext.args_samtools_view ?: ' -f 4 -h'
        def args_samtools_sort = task.ext.args_samtools_sort ?: " "
        def args_samtools_fastq = task.ext.args_samtools_fastq ?: " -NO "

        def output = meta.single_end ?
                    "${prefix}_unmapped_R1.fastq"
                    : "-1 ${prefix}_unmapped_R1.fastq -2 ${prefix}_unmapped_R2.fastq -s ${prefix}_unmapped_singletons.fastq"

        """
          samtools view $args_samtools_view $bam
          | samtools sort -@ ${task.cpus} $args_samtools_sort \\
          | samtools -@ ${task.cpus} $args_samtools_fastq - \\
          ${output} \\
          > ${prefix}.samtools_fastq.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
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
        touch ${prefix}.samtools_fastq.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        END_VERSIONS
        """

}

