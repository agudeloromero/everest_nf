process MMSEQ2_ETAXONOMY {
    tag "$meta.id : ${mode}"
    label 'process_medium'

    conda { params.conda_mmseqs2_env ?: "${projectDir}/envs/MMSEQS.yml" }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
         'https://depot.galaxyproject.org/singularity/mmseqs2:13.45111--h2d02072_0' :
         'quay.io/biocontainers/mmseqs2:13.45111--h2d02072_0' }"



    input:
    tuple val(meta), path(fasta)
    path(mmseq2_db)
    val(mode)

    output:
    tuple val(meta), val(mode)                   , emit: mode_tuple
    tuple val(meta), path("*lca.tsv")            , emit: lca
    tuple val(meta), path("*report")             , emit: report
    tuple val(meta), path("*tophit_aln")         , emit: tophit_aln
    tuple val(meta), path("*tophit_aln.txt")     , emit: tophit_aln_txt
    tuple val(meta), path("*tophit_report")      , emit: tophit_report
    tuple val("${task.process}"), val('mmseqs'), eval('mmseqs version'), emit: versions_mmseqs, topic: versions

    script:

    // Mode specific parameters
    def sen
    def args
    def ref_name

    if (mode == "aa") {
        ref_name = params.mmseq_viral_db_aa_ref_name
        sen   = "--start-sens 1 --sens-steps 3 -s 7 --lca-mode 3 --shuffle 0"
        args = task.ext.args ?: " --min-length 30 -a --tax-lineage 1 --search-type 2 -e 1e-5 --majority 0.5 --vote-mode 1"
    } else {
        ref_name = params.mmseq_viral_db_nt_ref_name
        sen   = "--start-sens 2 -s 7 --sens-steps 3"
        args = task.ext.args ?: " --min-length 100 -a --tax-lineage 2 --search-type 2 -e 1e-20"
    }

    // Common parameters
    def prefix = task.ext.prefix ?: "${meta.id}"
    def lca = task.ext.lca ?: "--lca-ranks superkingdom,phylum,class,order,family,genus,species"
    def output_format   = "--format-output query,target,evalue,pident,fident,nident,mismatch,qcov,tcov,qstart,qend,qlen,tstart,tend,tlen,alnlen,bits,qheader,theader,taxid,taxname,taxlineage"


    """
    # Retry-safety: on a Nomad in-place restart the workdir still holds attempt 1's
    # leftovers; mmseqs then refuses the existing scratch dir. Clear prior outputs/scratch
    # so the re-run starts clean. (Real fix is nf-nomad restart Attempts=0 -> fresh workdir;
    # see docs/cluster-resume/ISSUE-nf-nomad-inplace-restart-noclobber.md)
    rm -rf ${prefix}_${mode}_tmp ${prefix}_${mode}_lca.tsv ${prefix}_${mode}_report ${prefix}_${mode}_tophit_aln ${prefix}_${mode}_tophit_report ${prefix}_${mode}_tophit_aln.txt ${prefix}.mmseqs_etaxonomy_${mode}.log

    mmseqs easy-taxonomy \\
        --threads ${task.cpus} \\
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

    # Remove the mmseqs scratch dir (not a declared output): a leftover sub-dir in
    # the task workdir makes the nf-nomad-s5cmd recursive push-back stop at the
    # first directory and drop entries sorting after it (e.g. versions.yml).
    rm -rf ${prefix}_${mode}_tmp
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_${mode}_lca.tsv
    touch ${prefix}_${mode}_report
    touch ${prefix}_${mode}_tophit_aln
    touch ${prefix}_${mode}_tophit_aln.txt
    touch ${prefix}_${mode}_tophit_report
    """
}
