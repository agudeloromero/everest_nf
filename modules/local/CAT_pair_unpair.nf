process CAT_PAIR_UNPAIR {
        tag "$meta.id"
        label 'process_medium'

    //		conda (params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

        input:
        tuple val(meta), path(p1), path(p2)	
        tuple val(meta), path(up1), path(up2)
        
        output:
        tuple val(meta), path('*_trimm_cat_R1.fastq.gz'), path('*_trimm_cat_R2.fastq.gz')	, emit: concatenated
        tuple val(meta), path('*.log')						                                        , emit: log
        path "versions.yml"									                                              , emit: versions

        script:
    //		def args = task.ext.args ?: '-7'
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        cat $p1 $up1 > ${prefix}_trimm_cat_R1.fastq.gz \\
        cat $p2 $up2 > ${prefix}_trimm_cat_R2.fastq.gz \\
        > ${prefix}.CAT.pair_unpair.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
    //			CAT_pair_unpair: \$(trimmomatic --version)
        END_VERSIONS
        """


        stub:
        """
        """
}
