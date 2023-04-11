process TRIMM {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

        input:
        tuple val(meta), path(clean)
        path adapter


        output:
        tuple val(meta), path('*_trimm_pair_R1.fastq.gz'), path('*_trimm_pair_R2.fastq.gz')	    , emit: paired
        tuple val(meta), path('*_trimm_unpair_R1.fastq.gz'), path('*_trimm_unpair_R2.fastq.gz')	, emit: unpaired
        tuple val(meta), path('*.log')						                                              , emit: log
        path "versions.yml"									                                                    , emit: versions


        script:
            def args = task.ext.args ?: '7'
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            trimmomatic PE \\
            -threads $task.cpus \\
            -phred33 \\
            ${clean[0]} ${clean[1]} \\
            ${prefix}_trimm_pair_R1.fastq.gz  $up1 \\
            ${prefix}_trimm_pair_R2.fastq.gz $up2 \\
            > ${prefix}.trimm.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM: \$(trimmomatic --version)
            END_VERSIONS
            """

        stub:
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            touch ${prefix}_trimm_pair_R1.fastq.gz ${prefix}_trimm_pair_R2.fastq.gz
            touch ${prefix}_trimm_unpair_R1.fastq.gz ${prefix}_trimm_unpair_R2.fastq.gz
            touch ${prefix}.trimm.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM: \$(trimmomatic --version)
            END_VERSIONS
            """

}
