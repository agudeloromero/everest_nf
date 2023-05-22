include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_AA } from "../../modules/local/mmseq2_etaxonomy.nf"
//include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_NT } from "../../modules/local/mmseq2_etaxonomy.nf"


//include { TAXONKIT_REFORMAT as TAXONKIT_REFORMAT_AA } from "../../modules/local/taxonkit_reformat.nf"
//include { TAXONKIT_REFORMAT as TAXONKIT_REFORMAT_NT } from "../../modules/local/taxonkit_reformat.nf"



//include { SUMMARY_PER_SAMPLE as SUMMARY_PER_SAMPLE_NT } from "../../modules/local/summary_per_sample.nf"
//include { SUMMARY_PER_SAMPLE as SUMMARY_PER_SAMPLE_AA } from "../../modules/local/summary_per_sample.nf"



workflow TAXONOMY_WF {
    take:
        fasta_ch

    main:

         MMSEQ2_ETAXONOMY_AA( fasta_ch, params.mmseq_viral_db_aa, 'aa' )
 //        TAXONKIT_REFORMAT_AA(  MMSEQ2_ETAXONOMY_AA.out.lca, params.tax_aa )
         //SUMMARY_PER_SAMPLE
         //SUMMARY_COHORT



         //MMSEQ2_ETAXONOMY_NT( fasta_ch, params.mmseq_viral_db_nt, 'nt' )
         //TAXONKIT_REFORMAT_NT( MMSEQ2_ETAXONOMY_NT.out.lca, params.tax_nt )

    //emit:

}

