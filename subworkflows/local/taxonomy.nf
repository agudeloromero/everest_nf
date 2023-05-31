include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_AA    } from "../../modules/local/mmseq2_etaxonomy.nf"
include { TAXONKIT_REFORMAT as TAXONKIT_REFORMAT_AA   } from "../../modules/local/taxonkit_reformat.nf"
include { SUMMARY_PER_SAMPLE as SUMMARY_PER_SAMPLE_AA } from "../../modules/local/summary_per_sample.nf"
include { SUMMARY_COHORT as SUMMARY_COHORT_AA         } from "../../modules/local/summary_cohort.nf"

include { MMSEQ2_ETAXONOMY as  MMSEQ2_ETAXONOMY_NT    } from "../../modules/local/mmseq2_etaxonomy.nf"
include { TAXONKIT_REFORMAT as TAXONKIT_REFORMAT_NT   } from "../../modules/local/taxonkit_reformat.nf"
include { SUMMARY_PER_SAMPLE as SUMMARY_PER_SAMPLE_NT } from "../../modules/local/summary_per_sample.nf"
include { SUMMARY_COHORT as SUMMARY_COHORT_NT         } from "../../modules/local/summary_cohort.nf"

workflow TAXONOMY_WF {
    take:
        fasta_ch

    main:
/*
         MMSEQ2_ETAXONOMY_AA( fasta_ch, params.mmseq_viral_db_aa, 'aa' )
         TAXONKIT_REFORMAT_AA(  MMSEQ2_ETAXONOMY_AA.out.lca, params.tax_aa )
         SUMMARY_PER_SAMPLE_AA( TAXONKIT_REFORMAT_AA.out.lca_header )
         SUMMARY_COHORT_AA( SUMMARY_PER_SAMPLE_AA.out.summary )
*/

//FIXME: The entire folder needs to be symlinked

         MMSEQ2_ETAXONOMY_NT( fasta_ch, params.mmseq_viral_db_nt, 'nt' )
         TAXONKIT_REFORMAT_NT(  MMSEQ2_ETAXONOMY_NT.out.lca, params.tax_nt )


         in_summary_per_sample_nt_ch = MMSEQ2_ETAXONOMY_NT.out.mode_tuple
                                        .join(MMSEQ2_ETAXONOMY_NT.out.tophit_aln_txt)
                                        .join(TAXONKIT_REFORMAT_NT.out.lca_header)

         SUMMARY_PER_SAMPLE_NT( in_summary_per_sample_nt_ch,  params.baltimore_db)

         SUMMARY_COHORT_NT( SUMMARY_PER_SAMPLE_NT.out.summary.collect() )



    //emit:

}

