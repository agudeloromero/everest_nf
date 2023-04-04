process MINIMAP2_HOST_REMOVAL {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::minimap2=2.24 bioconda::samtools=1.9 bioconda::pigz=2.6' : null)

//        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
//            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        path index
        tuple val(meta), path(trimm_cat_fastqs)

        output:
        tuple val(meta), path('*_unmapped_R*.fastq')			              , emit: unmapped_pair
        tuple val(meta), path('*_unmapped_singletons.fastq')            , emit: unmapped_singleton
        tuple val(meta), path('*MINIMAP2_host_removal.log')	            , emit: log
        path "versions.yml"						                                  , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args_minimap2 = task.ext.args_minimap2 ?: '-ax sr --secondary=no'
        def args_samtools_view = task.ext.args_samtools_view ?: ' -f 4 -h'
        def args_samtools_sort = task.ext.args_samtools_sort ?: " -@ ${task.cpus}"
        def args_samtools_fastq = task.ext.args_samtools_fastq ?: " -NO -@ ${task.cpus}"


        """
        minimap2 $args_minimap2 -t ${task.cpus} $index ${trimm_cat_fastqs[0]} ${trimm_cat_fastqs[1]} \\
          | samtools view $args_samtools_view - 
          | samtools sort $args_samtools_sort \\
          | samtools $args_samtools_fastq - \\
          -1 ${prefix}_unmapped_R1.fastq \\
          -2 ${prefix}_unmapped_R2.fastq \\
          -s ${prefix}_unmapped_singletons.fastq \\
          > ${prefix}.MINIMAP2_host_removal.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(minimap2 --version 2>&1)
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
            pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
        END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
          touch ${prefix}_unmapped_R1.fastq
          touch ${prefix}_unmapped_R2.fastq
          touch ${prefix}_unmapped_singletons.fastq
          touch ${prefix}.MINIMAP2_host_removal.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(minimap2 --version 2>&1)
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
            pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
        END_VERSIONS
        """

}

