include { BBMAP_DEDUPE } from "../modules/local/bbmap_dedupe"


workflow {
    take:

    main:


        MINIMAP2_host_removal(
            MINIMAP2_index.out.index_ch

        )

    emit:
}
