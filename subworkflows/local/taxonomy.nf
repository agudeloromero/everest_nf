include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_AA } from "../../modules/local/mmseq2_etaxonomy.nf"
include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_NT } from "../../modules/local/mmseq2_etaxonomy.nf"

workflow TAXONOMY_WF {
    take:
        fasta_ch

    main:

         MMSEQ2_ETAXONOMY_AA( fasta_ch, 'aa', params.mmseq_viral_db_aa )

         MMSEQ2_ETAXONOMY_NT( fasta_ch, 'nt', params.mmseq_viral_db_nt )

        //MMSEQ_ETAXONOMY_ALN_HEADER_AA

        //TAXONKIT_REFORMATTED_AA

        //MMSEQ_ETAXONOMY_LCA_HEADER_AA

        //R_SUMMARY_SINGLE_AA

    //emit:
}

