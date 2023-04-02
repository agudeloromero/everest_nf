process MINIMAP2_HOST_REMOVAL {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::minimap2=2.24 bioconda::samtools=1.9 bioconda::pigz=2.6' : null)

//        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
//            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"

        input:
        tuple val(meta), path(concatenated)
        path index

        output:
        tuple val(meta), path('*_unmapped_R*.fastq')			, emit: unmapped_pair
        tuple val(meta), path('*_unmapped_singletons.fastq')            , emit: unmapped_single
        tuple val(meta), path('*S3P2_MINIMAP2_host_removal.log')	, emit: log
        path "versions.yml"						, emit: versions

        script:
        def args = task.ext.args ?: "-Xmx${task.memory}g"
        def args2 = task.ext.args2 ?: '-ax sr --secondary=no'
        def args4 = task.ext.args4 ?: 'view -f 4 -h'
        def args5 = task.ext.args ?: "sort -@ ${task.cpus}"
        def args6 = task.ext.args ?: "fastq -NO -@ ${task.cpus}"
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        minimap2 $args2 -t ${task.cpus} $index $cat1 $cat2 \\
          | samtools $args4 - | samtools $args5 \\
          | samtools fastq -NO -@ 7 - \\
          -1 ${prefix}_unmapped_R1.fastq -2 ${prefix}_unmapped_R2.fastq \\
          -s ${prefix}_unmapped_singletons.fastq
                > ${prefix}.MINIMAP2_host_removal.log

        minimap2_host_removal <<-END_VERSIONS > versions.yml
                "${task.process}":
                 minimap2: \$(bbversion.sh | grep -v "Duplicate cpuset")
                 samtools: \$(bbversion.sh | grep -v "Duplicate cpuset")
                pigz: \$(bbversion.sh | grep -v "Duplicate cpuset")
                END_VERSIONS
        """

