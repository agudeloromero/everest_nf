process BBMAP_PHIX {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::bbmap=38.96' : null)

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(reads)

        output:
        tuple val(meta), path('*_clean_R1.fastq.gz'), path('*_clean_R2.fastq.gz')	    , emit: clean
        tuple val(meta), path('*_noclean_R1.fastq.gz'), path('*_noclean_R2.fastq.gz')	, emit: unclean
        tuple val(meta), path('*_stats_phix.txt')		                                  , emit: stats_phix
        tuple val(meta), path('*.log')					                                      , emit: log
        path "versions.yml"								                                            , emit: versions

        script:
        def args = task.ext.args ?: '-Xmx20000m'
        def args2 = task.ext.args ?: 'ordered cardinality k=31 hdist=1'
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        bbduk.sh \\
          --cores $task.cpus \\ 
          $args \\
          in1=$reads[0] in2=$reads[1] \\ 
          out1=${prefix}_clean_R1.fastq.gz out2=${prefix}_clean_R2.fastq.gz  \\
          outm1=${prefix}_noclean_R1.fastq.gz outm2=${prefix}_noclean_R2.fastq.gz \\
          ref=artifacts,phix \\
          stats=$stats_phix \\
          $arg2 \\
          > ${prefix}.bbmap_phix.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
          BBMAP_phix: \$(bbmap --version)
        END_VERSIONS
        """
}
