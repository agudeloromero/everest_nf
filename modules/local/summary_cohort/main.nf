process SUMMARY_COHORT {
        label 'process_low'
        stageInMode "copy"

        conda { params.conda_r_env ?: "${projectDir}/envs/R.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
           'docker://quay.io/biocontainers/r-base:4.2.1':
           'quay.io/biocontainers/r-base:4.2.1' }"



        input:
        path("*")
        val(mode)

        output:
        tuple val(mode), path("EVEREST_cohort_${mode}.txt")   , emit: summary
        tuple val("${task.process}"), val('r-base'), eval('R --version 2>&1 | head -1 | sed "s/^.*R version //; s/ .*//"'), emit: versions_r_base, topic: versions

        script:
        def args = task.ext.args ?: ""


        """
            Summary_CombineSamples_script.R  ./ "_${mode}_"  EVEREST_cohort_${mode}.txt
        """

        stub:

        """
            touch EVEREST_cohort_${mode}.txt
        """

}
