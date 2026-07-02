process CAT_PAIR_UNPAIR {
        tag "$meta.id"
        label 'process_medium'

        //NOTE: For the cat utility, we simply reuse the bbmap container
        conda { params.conda_bbmap_env ?: "${projectDir}/envs/BBMAP.yml" }

        container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/bbmap:38.96--h5c4e2a8_0':
            'quay.io/biocontainers/bbmap:38.96--h5c4e2a8_0' }"


        input:
        tuple val(meta), path(paired), path(unpaired)

        output:
        tuple val(meta), path('*_trimm_cat_R*.fastq.gz')	, emit: concatenated
        tuple val("${task.process}"), val('cat'), eval('cat --help 2>&1 | grep -o "BusyBox v[0-9.]*" | sed "s/BusyBox v//"'), emit: versions_cat_pair_unpair, topic: versions

        script:
        def args = task.ext.args ?: '-7'
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        cat ${paired[0]} ${unpaired[0]} > ${prefix}_trimm_cat_R1.fastq.gz
        cat ${paired[0]} ${unpaired[1]} > ${prefix}_trimm_cat_R2.fastq.gz
        """


        stub:
        def prefix = task.ext.prefix ?: "${meta.id}"

        """
        touch ${prefix}_trimm_cat_R1.fastq.gz
        touch ${prefix}_trimm_cat_R2.fastq.gz
        """
}
