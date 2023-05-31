process SUMMARY_PER_SAMPLE {
        tag "$meta.id"
        label 'process_medium'
        stageInMode "copy"

        conda { params.conda_r_env ?: "${projectDir}/envs/R.yml" }

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), val(mode), path(lca_file), path(aln_file)
        path(baltimore_db)

        output:
        path("${prefix}_summary_${mode}.txt")                 , emit: summary
        path "versions.yml"			                          , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: ""


        """
            Summary_script.R ${lca_file} ${aln_file} ${baltimore_db} ${prefix}_summary_${mode}.txt \\
            2> ${prefix}_summary_${mode}.log

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    FIXME: \$( pigz --version 2>&1 | sed 's/pigz //g' )
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            touch ${prefix}_summary_${mode}.txt
            touch ${prefix}_summary_${mode}.log

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    FIXME: \$( pigz --version 2>&1 | sed 's/pigz //g' )
            END_VERSIONS
        """

}
