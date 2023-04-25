process CAT_PAIR_UNPAIR {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_minimap2_env ?: "${projectDir}/envs/minimap2.yml" }

        input:
        tuple val(meta), path(paired), path(unpaired)
        
        output:
        tuple val(meta), path('*_trimm_cat_R*.fastq.gz')	, emit: concatenated
        tuple val(meta), path('*.log')						        , emit: log
        path "versions.yml"									              , emit: versions

        script:
        def args = task.ext.args ?: '-7'
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        cat ${paired[0]} ${unpaired[0]} > ${prefix}_trimm_cat_R1.fastq.gz \\
        cat ${paired[0]} ${unpaired[1]} > ${prefix}_trimm_cat_R2.fastq.gz \\
        > ${prefix}.CAT.pair_unpair.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            CAT_PAIR_UNPAIR: \$(cat --version)
        END_VERSIONS
        """


        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        touch ${prefix}_trimm_cat_R1.fastq.gz
        touch ${prefix}_trimm_cat_R2.fastq.gz
        touch ${prefix}.CAT.pair_unpair.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            CAT_pair_unpair: \$(cat --version)
        END_VERSIONS
        """
}
