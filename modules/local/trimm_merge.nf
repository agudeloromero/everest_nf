process TRIMM_MERGE {
        tag "$meta.id"
        label 'process_medium'

        conda (params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

        input:
        tuple val(meta), path(reads)
        path adapter


        output:
        tuple val(meta), path('*_trimm_pair_R1.fastq.gz'), path('*_trimm_pair_R2.fastq.gz')	    , emit: paired
        tuple val(meta), path('*.log')						                                              , emit: log
        path "versions.yml"									                                                    , emit: versions


        script:
            def args = task.ext.args ?: ' LEADING:10 TRAILING:10 SLIDINGWINDOW:3:15 MINLEN:50 '
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            trimmomatic PE \\
            -threads $task.cpus \\
            -phred33 \\
            ${reads[0]} ${reads[1]} \\
            ${prefix}_unmapped_cat_unmerge_pair_R1.fastq.gz \\
            ${prefix}_unmapped_cat_unmerge_unpair_R1.fastq.gz \\
            ${prefix}_unmapped_cat_unmerge_pair_R2.fastq.gz \\
            ${prefix}_unmapped_cat_unmerge_unpair_R2.fastq.gz \\
            ILLUMINACLIP:${adapter}:2:30:10 \\
            ${args} \\
            2> ${prefix}.trimm_merge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_MERGE: \$(trimmomatic --version)
            END_VERSIONS
            """

        stub:
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            touch ${prefix}_trimm_pair_R1.fastq.gz ${prefix}_trimm_pair_R2.fastq.gz
            touch ${prefix}_trimm_unpair_R1.fastq.gz ${prefix}_trimm_unpair_R2.fastq.gz
            touch ${prefix}.trimm_merge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_MERGE: \$(trimmomatic --version)
            END_VERSIONS
            """

}
