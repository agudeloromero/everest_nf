include { ABRICATE_RUN           } from "../../modules/nf-core/abricate/run/main.nf"
include { ABRICATE_SUMMARY       } from '../../modules/nf-core/abricate/summary/main'
include { SEQKIT_FILTER          } from "../../modules/local/seqkit_filter.nf"
include { PHAROKKA               } from "../../modules/local/pharokka.nf"
include { VIRSORTER_DETECT       } from "../../modules/local/virsorter_detect.nf"
include { CHECKV_VIRAL_SEQ       } from "../../modules/local/checkv_viral_seq.nf"
include { BACPHLIP_LIFE_STYLE    } from "../../modules/local/bacphlip_life_style.nf"
include { BBMAP_MAPPING_CONTIGS  } from "../../modules/local/bbmap_mapping_contigs.nf"

workflow CLEANING_CONTIGS_WF {

    take:
        raw_fastqs
        repseq_fasta

    main:
        SEQKIT_FILTER( repseq_fasta )

        //VIRSORTER_DETECT( SEQKIT_FILTER.out.filtered_fasta, params.virsorter_db )



    //NOTE: The output of nanopore analysis should be the the input for CHECKV
        CHECKV_VIRAL_SEQ( SEQKIT_FILTER.out.filtered_fasta, params.checkv_db )


        //CHECKV_VIRAL_SEQ.out.renamed_fasta.dump(tag: "CHECKV_VIRAL_SEQ.out")
        //raw_fastqs.dump(tag: "raw_fastqs")

        in_bbmap_mapping_contigs_ch = CHECKV_VIRAL_SEQ.out.renamed_fasta
                                        .join(raw_fastqs)
                                        .dump(tag: "in_bbmap_mapping_contigs_ch")


        BBMAP_MAPPING_CONTIGS( in_bbmap_mapping_contigs_ch )


        ABRICATE_RUN( CHECKV_VIRAL_SEQ.out.renamed_fasta, [] )

        ABRICATE_SUMMARY (
            ABRICATE_RUN.out.report.collect { meta, report -> report }.map{ report -> [[ id: 'summary'], report]}
        )

        BACPHLIP_LIFE_STYLE( CHECKV_VIRAL_SEQ.out.renamed_fasta )


    emit:
        fasta = CHECKV_VIRAL_SEQ.out.renamed_fasta

}
