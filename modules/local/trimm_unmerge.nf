process TRIMM_UNMERGE {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_qc_env ?: "${projectDir}/envs/QC.yml"  }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trimmomatic:0.39--hdfd78af_2':
        'biocontainers/trimmomatic:0.39--hdfd78af_2' }"


        input:
        tuple val(meta), path(reads)
        path adaptor


        output:
        tuple val(meta), path('*_unmapped_cat_unmerge_pair_R*.fastq.gz')                                  , emit: paired
        tuple val(meta), path('*_unmapped_cat_unmerge_unpair_R*.fastq.gz')                              , emit: unpaired
        tuple val(meta), path('*.log')                                                                            , emit: log
        path "versions.yml"                                                                                             , emit: versions


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
            ILLUMINACLIP:${adaptor}:2:30:10 \\
            ${args} \\
            2> ${prefix}.trimm_unmerge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_UNMERGE: \$(trimmomatic -version)
            END_VERSIONS
            """

        stub:
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            touch ${prefix}_unmapped_cat_unmerge_pair_R1.fastq.gz
            touch ${prefix}_unmapped_cat_unmerge_unpair_R1.fastq.gz
            touch ${prefix}_unmapped_cat_unmerge_pair_R2.fastq.gz
            touch ${prefix}_unmapped_cat_unmerge_unpair_R2.fastq.gz

            touch ${prefix}.trimm_unmerge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_UNMERGE: \$(trimmomatic -version)
            END_VERSIONS
            """

}
