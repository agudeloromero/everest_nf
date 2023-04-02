process MINIMAP2_HOST_REMOVAL {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::minimap2=2.24 bioconda::samtools=1.9 bioconda::pigz=2.6' : null)

//        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
//            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        tuple val(meta), path(trimm_cat_fastqs)
        path index

        output:
        tuple val(meta), path('*_unmapped_R*.fastq')			              , emit: unmapped_pair
        tuple val(meta), path('*_unmapped_singletons.fastq')            , emit: unmapped_single
        tuple val(meta), path('*MINIMAP2_host_removal.log')	      , emit: log
        path "versions.yml"						                                  , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def minimap2_args = task.ext.minimap2_args ?: '-ax sr --secondary=no'
        def samtools_view_args = task.ext.samtools_view_args ?: ' -f 4 -h'
        def samtools_sort_args = task.ext.samtools_sort_args ?: " -@ ${task.cpus}"
        def samtools_fastq_args = task.ext.samtools_fastq_args ?: " -NO -@ ${task.cpus}"


        """
        minimap2 $minimap2_args -t ${task.cpus} $index ${trimm_cat_fastqs[0]} ${trimm_cat_fastqs[1]} \\
          | samtools view $samtools_view_args - 
          | samtools sort $samtools_sort_args \\
          | samtools $samtools_fastq_args - \\
          -1 ${prefix}_unmapped_R1.fastq \\
          -2 ${prefix}_unmapped_R2.fastq \\
          -s ${prefix}_unmapped_singletons.fastq \\
          > ${prefix}.MINIMAP2_host_removal.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            minimap2: \$(bbversion.sh | grep -v "Duplicate cpuset")
            samtools: \$(bbversion.sh | grep -v "Duplicate cpuset")
            pigz: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}
