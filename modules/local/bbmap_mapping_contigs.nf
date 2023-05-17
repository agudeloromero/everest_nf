process BBMAP_MAPPING_CONTIGS {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

    /* container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? */
    /*         'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0': */
    /*         'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }" */


    input:
    tuple val(meta), path(renamed_fasta), path(reads)

    output:
    tuple val(meta), path("*_contig.sam")               , emit: sam
    tuple val(meta), path("*_contig_rpk.txt")           , emit: rpk
    tuple val(meta), path("*_contig_scafstats.txt")     , emit: scafstats
    tuple val(meta), path("*_contig_covstats.txt")      , emit: covstats
    path "versions.yml"                                 , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: " -Xmx${task.memory.toMega()}m nodisk slow=t ambiguous=random threads=${task.cpus} "

    def input = meta.single_end ?
                "in=${reads[0]}"
                : "in1=${reads[0]} in2=${reads[1]}"

    """
    bbmap.sh ${args} \\
        ref=${renamed_fasta} \\
        ${input} \\
        out=${prefix}_contig.sam \\
        rpkm=${prefix}_contig_rpk.txt \\
        scafstats=${prefix}_contig_scafstats.txt \\
        covstats=${prefix}_contig_covstats.txt \\
    2> ${prefix}.bbmap_mapping_contigs.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_contig.sam
    touch ${prefix}_contig_rpk.txt
    touch ${prefix}_contig_scafstats.txt
    touch ${prefix}_contig_covstats.txt

    touch ${prefix}.bbmap_mapping_contigs.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dedupe.sh: \$(bbversion.sh | grep -v "Duplicate cpuset")
    END_VERSIONS
    """

}
