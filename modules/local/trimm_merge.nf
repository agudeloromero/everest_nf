process TRIMM_MERGE {
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
        tuple val(meta), path("*_unmapped_cat_R1_merge_trimm.fastq.gz")                 , emit: paired
        tuple val(meta), path('*.log')                                                  , emit: log
        path "versions.yml"                                                             , emit: versions


        script:
            def args = task.ext.args ?: '-phred33 LEADING:10 TRAILING:10 SLIDINGWINDOW:3:15 MINLEN:50 '
            def prefix = task.ext.prefix ?: "${meta.id}"

            //NOTE: Hard-coded since we only operate upon the R1
            def trimmed = "SE"

            """
            trimmomatic $trimmed \\
            -threads $task.cpus \\
            ${reads[0]} \\
            ${prefix}_unmapped_cat_R1_merge_trimm.fastq.gz \\
            ILLUMINACLIP:${adaptor}:2:30:10 \\
            ${args} \\
            2> ${prefix}.trimm_merge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_MERGE: \$(trimmomatic -version)
            END_VERSIONS
            """

        stub:
            def prefix = task.ext.prefix ?: "${meta.id}"

            """
            touch ${prefix}_unmapped_cat_R1_merge_trimm.fastq.gz
            touch ${prefix}.trimm_merge.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
              TRIMM_MERGE: \$(trimmomatic -version)
            END_VERSIONS
            """

}
