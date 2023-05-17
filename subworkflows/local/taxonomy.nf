include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_AA } from "../../modules/local/mmseq2_etaxonomy.nf"
include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_NT } from "../../modules/local/mmseq2_etaxonomy.nf"

workflow TAXONOMY_WF {
    take:
        fasta_ch

    main:

         MMSEQ2_ETAXONOMY_AA( fasta_ch, params.mmseq_viral_db_aa, 'aa' )
         MMSEQ2_ETAXONOMY_NT( fasta_ch, params.mmseq_viral_db_nt, 'nt' )

        //MMSEQ_ETAXONOMY_ALN_HEADER

        //TAXONKIT_REFORMATTED

        //MMSEQ_ETAXONOMY_LCA_HEADER

        //R_SUMMARY_SINGLE

    //emit:
}

