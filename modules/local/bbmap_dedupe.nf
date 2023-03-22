process BBMAP_DEDUPE {
    tag "$meta.id"
    label 'process_medium'

    conda "envs/minimap2.yml"
    /* TODO: Add containers to all modules later */
    /* container */

    //Below are the most frequent directives
    input:
    tuple val(meta), path(reads)

    output:
    path("bbmap_dedupe.out")

    script:

    """
    dedupe.sh ${task.memory} ${args} in1=${reads{0}} in2=${reads{1}} out=bbmap_dedupe.out 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """


    stub:
    """
    touch bbmap_dedupe.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      BBMAP_DEDUPE: \$(bbmap --version)
    END_VERSIONS
    """

}
