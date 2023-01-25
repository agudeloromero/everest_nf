process BBMAP_DEDUPE {
    tag "$meta.id"
    label 'process_medium'

    conda "envs/minimap2.yml"
    /* TODO: Add containers to all modules later */
    /* container */

    //Below are the most frequent directives
    input:
    tuple path(f1), path(f2)

    output:
    path("bbmap_dedupe.out")

    script:

    """
    dedupe.sh ${params.mem} ${params.other} in1=${f1} in2=${f2} out=bbmap_dedupe.out 
    """
}
