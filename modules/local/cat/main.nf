process CAT {
        tag "$meta.id"
        label 'process_medium'

        //NOTE: For the cat utility, we simply reuse the bbmap container
        conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(unmapped_pair), path(singleton_pair)

        output:
        tuple val(meta), path('*_unmapped_cat_R*.fastq')                        , emit: fastq
        tuple val("${task.process}"), val('cat'), eval('cat --help 2>&1 | grep -o "BusyBox v[0-9.]*" | sed "s/BusyBox v//"'), emit: versions_cat, topic: versions

        script:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            cat ${unmapped_pair[0]} ${singleton_pair[0]} > ${prefix}_unmapped_cat_R1.fastq

            cat ${unmapped_pair[1]} ${singleton_pair[1]} > ${prefix}_unmapped_cat_R2.fastq
        """

        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
            touch ${prefix}_unmapped_cat_R1.fastq
            touch ${prefix}_unmapped_cat_R2.fastq

        """

}
