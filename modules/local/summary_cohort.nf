process SUMMARY_COHORT {
        label 'process_low'
        stageInMode "copy"

        conda { params.conda_r_env ?: "${projectDir}/envs/R.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
           'build_R--ec6ca86def5d06b7.sif':
           'FIXME' }"


        input:
        path("*")
        val(mode)

        output:
        path "versions.yml"			                          , emit: versions

        script:
        def args = task.ext.args ?: ""


        """
            Summary_CombineSamples_script.R  ./ "_${mode}_"  Summary_mmseqs2_${mode}.log

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
            END_VERSIONS
        """

        stub:

        """
            touch Summary_mmseqs2_${mode}.log

            cat <<-END_VERSIONS > versions.yml
                "${task.process}":
                    r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
            END_VERSIONS
        """

}

