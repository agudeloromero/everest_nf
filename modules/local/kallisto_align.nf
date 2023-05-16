process KALLISTO_ALIGN {
        tag "$meta.id"
        label 'process_medium'

        conda { params.conda_kallisto_env ?: "${projectDir}/envs/kallisto.yml" }

 //       container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
 //           'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
 //           'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(reads)
        path(idx)

        output:
        tuple val(meta), path('alignment/pseudoalignments.bam')	    , emit: bam
        path("kallisto_align_*.log")	                            , emit: log
        path "versions.yml"			                                , emit: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        def args = task.ext.args ?: " -t ${task.cpus}"
        def input = meta.single_end ?
                    "--single -l 200 -s 200 $reads"
                    : "$reads"


        """
            kallisto quant $args -i $idx \\
            $input \\
            -o alignment \\
            --pseudobam \\
            2> kallisto_align_${prefix}.log

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                kallisto: \$(echo \$(kallisto 2>&1) | sed 's/^kallisto //; s/Usage.*\$//')
            END_VERSIONS
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        stub:
        """
        mkdir alignment
        touch alignment/pseudoalignments.bam
        touch kallisto_align_${prefix}.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            kallisto: \$(echo \$(kallisto 2>&1) | sed 's/^kallisto //; s/Usage.*\$//')
        END_VERSIONS
        """

}

