
workflow CLEANING_CONTIGS { 

    take: 


    main: 
        SEQKIT_FILTER

        VIRSORTER_DETECT

        CHECKV_VIRAL_SEQ

        //TODO: Maybe, not needed
        RENAME_VIRAL_SEQ

        BBMAP_MAPPING_CONTIGS

        BACPHLIP_LIFE_STYLE

    emit: 

}

