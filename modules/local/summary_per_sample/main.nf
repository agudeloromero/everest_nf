process SUMMARY_PER_SAMPLE {
        tag "$meta.id"
        label 'process_medium'
        stageInMode "copy"

        conda { params.conda_r_env ?: "${projectDir}/envs/R.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
           'docker://quay.io/biocontainers/r-base:4.2.1':
           'quay.io/biocontainers/r-base:4.2.1' }"


        input:
        tuple val(meta), val(mode), path(aln_file), path(lca_file)
        path(baltimore_db)

        output:
        path("*_summary_${mode}.txt")                         , emit: summary
        tuple val("${task.process}"), val('r-base'), eval('R --version 2>&1 | head -1 | sed "s/^.*R version //; s/ .*//"'), emit: versions_r_base, topic: versions

        script:
        prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: ""


        """
            Summary_script.R ${lca_file} ${aln_file} ${baltimore_db} ${prefix}_summary_${mode}.txt \\
            2> ${prefix}_summary_${mode}.log
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            touch ${prefix}_summary_${mode}.txt
            touch ${prefix}_summary_${mode}.log
        """

}
