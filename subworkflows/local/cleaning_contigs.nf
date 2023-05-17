include { SEQKIT_FILTER          } from "../../modules/local/seqkit_filter.nf"
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

        VIRSORTER_DETECT( SEQKIT_FILTER.out.filtered_fasta, params.virsorter_db )

        CHECKV_VIRAL_SEQ( VIRSORTER_DETECT.out.combined, params.checkv_db )


        //CHECKV_VIRAL_SEQ.out.renamed_fasta.dump(tag: "CHECKV_VIRAL_SEQ.out")
        //raw_fastqs.dump(tag: "raw_fastqs")

        in_bbmap_mapping_contigs_ch = CHECKV_VIRAL_SEQ.out.renamed_fasta
                                        .join(raw_fastqs)
                                        .dump(tag: "in_bbmap_mapping_contigs_ch")

        BBMAP_MAPPING_CONTIGS( in_bbmap_mapping_contigs_ch )

        //FIXME This complains about not receiving multi-fasta sequences
        //BACPHLIP_LIFE_STYLE( CHECKV_VIRAL_SEQ.out.renamed_fasta )

    emit:
        fasta = CHECKV_VIRAL_SEQ.out.renamed_fasta

}

