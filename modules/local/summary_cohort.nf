process SUMMARY_COHORT {
        label 'process_medium'
        stageInMode "copy"

        conda { params.conda_r_env ?: "${projectDir}/envs/R.yml" }

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


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

