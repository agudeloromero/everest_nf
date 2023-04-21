process TRIMM {
        tag "$meta.id"
        label 'process_medium'

        conda "${projectDir}/envs/QC.yml" //(params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

        input:
        tuple val(meta), path(cleaned_reads)
        path adapter


        output:
        tuple val(meta), path('*_trimm_pair_R*.fastq.gz')                                       , emit: paired
        tuple val(meta), path('*_trimm_unpair_R*.fastq.gz')	                                    , emit: unpaired, optional: true
        tuple val(meta), path('*.log')						                                              , emit: log
        path "versions.yml"									                                                    , emit: versions


        script:
            def args = task.ext.args ?: '-phred33'
            def prefix = task.ext.prefix ?: "${meta.id}"
            def trimmed = meta.single_end ? "SE" : "PE"
            def output = meta.single_end ?
                "${prefix}._trimm_pair_R1.fastq.gz" 
                : "${prefix}._trimm_pair_R1.fastq.gz ${prefix}._trimm_unpair_R1.fastq.gz ${prefix}._trimm_pair_R2.fastq.gz ${prefix}._trimm_unpair_R2.fastq.gz"

            """
            trimmomatic $trimmed \\
            -threads $task.cpus \\
            ${args} \\
            ${cleaned_reads} \\
            ${output} \\
            > ${prefix}.trimm.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM: \$(trimmomatic --version)
            END_VERSIONS
            """

        stub:
            def prefix = task.ext.prefix ?: "${meta.id}"
            def output = meta.single_end ?
                "${prefix}._trimm_pair_R1.fastq.gz" 
                : "${prefix}._trimm_pair_R1.fastq.gz ${prefix}._trimm_unpair_R1.fastq.gz ${prefix}._trimm_pair_R2.fastq.gz ${prefix}._trimm_unpair_R2.fastq.gz"


            """
            touch ${output}
            touch ${prefix}.trimm.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM: \$(trimmomatic --version)
            END_VERSIONS
            """

}
