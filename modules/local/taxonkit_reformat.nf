process TAXONKIT_REFORMAT {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_taxonkit_env ?: "${projectDir}/envs/taxonkit.yml" }


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/taxonkit:2.1.0--h9ee0642_0' :
        'quay.io/biocontainers/taxonkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(lca)
    path(tax_db)

    output:
    tuple val(meta), path("*_lca_reformatted.tsv")           , emit: lca_reformatted
    tuple val(meta), path("*_lca_reformatted_header.tsv")    , emit: lca_header
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output = lca.baseName + "_reformatted" + ".tsv"
    def log = lca.baseName + "_reformatted" + ".log"
    def header = lca.baseName + "_reformatted_header" + ".tsv"

    """
    taxonkit lineage \\
        $lca \\
        --data-dir ${tax_db} \\
        -i 2 \\
    | taxonkit reformat --data-dir ${tax_db} -i 7 -f "{k}\\t{p}\\t{c}\\t{o}\\t{f}\\t{g}\\t{s}" -F --fill-miss-rank \\
    | cut --complement -f5,6 \\
    > ${output} \\
    2> ${log}

    sed '1 i\\lca_query\tlca_taxid\tlca_taxonomic_rank\tlca_taxonomic_name\tlca_taxlineage\tlca_kingdom\tlca_phylum\tlca_class\tlca_order\tlca_family\tlca_genus\tlca_species' ${output} > ${header}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonkit: \$(echo \$(taxonkit version 2>&1) | sed 's/taxonkit v*//g')
    END_VERSIONS
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_rep_seq_FilterLen.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonkit: \$(echo \$(taxonkit version 2>&1) | sed 's/taxonkit v*//g')
    END_VERSIONS
    """

}
