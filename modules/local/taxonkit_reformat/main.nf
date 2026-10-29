process TAXONKIT_REFORMAT {
    tag "$meta.id"
    label 'process_medium'

    conda { params.conda_taxonkit_env ?: "${projectDir}/envs/taxonkit.yml" }


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://community.wave.seqera.io/library/coreutils_taxonkit:f9e457f496196bee' :
        'community.wave.seqera.io/library/coreutils_taxonkit:f9e457f496196bee' }"

    input:
    tuple val(meta), path(lca)
    path(tax_db)
    val(tax_db_mounted)   // set (and tax_db empty) when --db_mounted_dir is used

    output:
    tuple val(meta), path("*_lca_reformatted.tsv")           , emit: lca_reformatted
    tuple val(meta), path("*_lca_reformatted_header.tsv")    , emit: lca_header
    tuple val("${task.process}"), val('taxonkit'), eval('taxonkit version 2>&1 | sed "s/taxonkit v*//g"'), emit: versions_taxonkit, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output = lca.baseName + "_reformatted" + ".tsv"
    def db = tax_db_mounted ?: tax_db
    def log = lca.baseName + "_reformatted" + ".log"
    def header = lca.baseName + "_reformatted_header" + ".tsv"

    """
    # MMseqs2 majority/vote-mode LCA (the amino-acid search) inserts four stats columns
    # (nfrag, nlabeled, nsupport, fraction) after the taxon name; drop them so both modes
    # share the 6-column layout the -i 7 / cut below assume. Otherwise the lineage columns
    # shift and every AA summary comes out empty.
    awk -F'\\t' -v OFS='\\t' '{
        if (NF >= 9 && \$5 ~ /^[0-9]+\$/ && \$8 ~ /^[0-9.]+\$/) {
            line = \$1 OFS \$2 OFS \$3 OFS \$4
            for (i = 9; i <= NF; i++) line = line OFS \$i
            print line
        } else print
    }' $lca > ${lca.baseName}_norm.tsv

    taxonkit lineage \\
        ${lca.baseName}_norm.tsv \\
        --data-dir ${db} \\
        -i 2 \\
    | taxonkit reformat --data-dir ${db} -i 7 -f "{k}\\t{p}\\t{c}\\t{o}\\t{f}\\t{g}\\t{s}" -F --fill-miss-rank \\
    | cut --complement -f5,6 \\
    > ${output} \\
    2> ${log}

    sed '1 i\\lca_query\tlca_taxid\tlca_taxonomic_rank\tlca_taxonomic_name\tlca_taxlineage\tlca_kingdom\tlca_phylum\tlca_class\tlca_order\tlca_family\tlca_genus\tlca_species' ${output} > ${header}
    """

    stub:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_lca_reformatted.tsv
    touch ${prefix}_lca_reformatted_header.tsv
    """

}
