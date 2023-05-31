process MMSEQ2_ETAXONOMY {
    tag "$meta.id : ${mode}"
    label 'process_medium'

    conda { params.conda_mmseqs2_env ?: "${projectDir}/envs/MMSEQS.yml" }

    /* container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? */
    /*     'https://depot.galaxyproject.org/singularity/spades:3.15.5--h95f258a_1' : */
    /*     'quay.io/biocontainers/spades:3.15.5--h95f258a_1' }" */

    input:
    tuple val(meta), path(fasta)
    path(mmseq2_db)
    val(mode)

    output:
    tuple val(meta), val(mode)                   , emit: mode_tuple
    tuple val(meta), path("*lca")                , emit: lca
    tuple val(meta), path("*report")             , emit: report
    tuple val(meta), path("*tophit_aln")         , emit: tophit_aln
    tuple val(meta), path("*tophit_aln.txt")     , emit: tophit_aln_txt
    tuple val(meta), path("*tophit_report")      , emit: tophit_report
    path  "versions.yml"                         , emit: versions

    script:

    // Mode specific parameters
    def sen
    def args
    def ref_name

    if (mode == "aa") {
        ref_name = params.mmseq_viral_db_aa_ref_name
		sen   = "--start-sens 1 --sens-steps 3 -s 7 --lca-mode 3 --shuffle 0"
        args = task.ext.args ?: "--threads ${task.cpus} --min-length 30 -a --tax-lineage 1 --search-type 2 -e 1e-5 --majority 0.5 --vote-mode 1"
    } else {
        ref_name = params.mmseq_viral_db_nt_ref_name
		sen   = "--start-sens 2 -s 7 --sens-steps 3"
        args = task.ext.args ?: "--threads ${task.cpus} --min-length 100 -a --tax-lineage 2 --search-type 2 -e 1e-20"
    }

    // Common parameters
    def prefix = task.ext.prefix ?: "${meta.id}"
    def lca = task.ext.lca ?: "--lca-ranks superkingdom,phylum,class,order,family,genus,species"
	def output_format   = "--format-output query,target,evalue,pident,fident,nident,mismatch,qcov,tcov,qstart,qend,qlen,tstart,tend,tlen,alnlen,bits,qheader,theader,taxid,taxname,taxlineage"


    """
    mmseqs easy-taxonomy \\
        ${fasta} \\
        ${mmseq2_db}/${ref_name} \\
        ${prefix}_${mode} \\
        ${prefix}_${mode}_tmp \\
        ${args} \\
        ${lca} \\
        ${sen} \\
        ${output_format} \\
    2> ${prefix}.mmseqs_etaxonomy_${mode}.log

    sed '1i aln_query\taln_target\taln_evalue\taln_pident\taln_fident\taln_nident\taln_mismatch\taln_qcov\taln_tcov\taln_qstart\taln_qend\taln_qlen\taln_tstart\taln_tend\taln_tlen\taln_alnlen\taln_bits\taln_qheader\taln_theader\taln_taxid\taln_taxname\taln_taxlineage' ${prefix}_${mode}_tophit_aln > ${prefix}_${mode}_tophit_aln.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs --help | grep 'MMseqs2 Version' | sed 's/^MMseqs2 Version: //; s/\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    ${prefix}.lca
    ${prefix}.report
    ${prefix}.tophit_aln
    ${prefix}.tophit_report

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs --help | grep 'MMseqs2 Version' | sed 's/^MMseqs2 Version: //; s/\$//')
    END_VERSIONS
    """
}
