include { MMSEQ2_ETAXONOMY } from "../../modules/local/mmseq2_etaxonomy.nf"

workflow TAXONOMY_WF {
    take:
        fasta_ch

    main:

        MMSEQ2_ETAXONOMY( fasta_ch, 'aa', params.mmseq_viral_db_aa )

        //MMSEQ_ETAXONOMY_ALN_HEADER_AA

        //TAXONKIT_REFORMATTED_AA

        //MMSEQ_ETAXONOMY_LCA_HEADER_AA

        //R_SUMMARY_SINGLE_AA

    //emit:
}


