process BBMAP_PHIX {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*_clean_R*.fastq.gz')	                              , emit: clean
        tuple val(meta), path('*_noclean_R*.fastq.gz')	                              , emit: unclean
        tuple val(meta), path('*stats_phix.txt')		                              , emit: stats_phix
        tuple val(meta), path('*bbmap_phix.log')					                  , emit: log
        path "versions.yml"								                              , emit: versions

        script:
        def args = task.ext.args ?: '-Xmx20000m'
        def args2 = task.ext.args ?: 'ordered=t cardinality=t k=31 hdist=1'
        def prefix = task.ext.prefix ?: "${meta.id}"

        def input = meta.single_end ? "in=${reads[0]}" : "in1=${reads[0]} in2=${reads[1]}"
        def output_clean = meta.single_end ? "out=${prefix}_clean_R1.fastq.gz" : "out1=${prefix}_clean_R1.fastq.gz out2=${prefix}_clean_R2.fastq.gz"
        def output_noclean = meta.single_end ? "outm=${prefix}_noclean_R1.fastq.gz" : "outm1=${prefix}_noclean_R1.fastq.gz outm2=${prefix}_noclean_R2.fastq.gz"

        """
        bbduk.sh \\
          $args \\
          ${input} \\
          ${output_clean} \\
          ${output_noclean} \\
          ref=artifacts,phix \\
          stats=${prefix}.stats_phix.txt \\
          $args2 \\
          2> ${prefix}.bbmap_phix.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          bbduk: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """


        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        def input = meta.single_end ? "${reads[0]}" : "${reads[0]} ${reads[1]}"
        def output_clean = meta.single_end ? "${prefix}_clean_R1.fastq.gz" : "${prefix}_clean_R1.fastq.gz ${prefix}_clean_R2.fastq.gz"
        def output_noclean = meta.single_end ? "${prefix}_noclean_R1.fastq.gz" : "${prefix}_noclean_R1.fastq.gz ${prefix}_noclean_R2.fastq.gz"


        """
        touch ${input}
        touch ${output_clean}
        touch ${output_noclean}

        touch ${prefix}.stats_phix.txt
        touch ${prefix}.bbmap_phix.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            bbduk: \$(bbversion.sh | grep -v "Duplicate cpuset")
        END_VERSIONS
        """
}
