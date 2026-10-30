process NANOQ {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/nanoq:0.10.0--h031d066_2'
        : 'biocontainers/nanoq:0.10.0--h031d066_2'}"

    input:
    tuple val(meta), path(ontreads)
    val(output_format) //One of the following: fastq, fastq.gz, fastq.bz2, fastq.lzma, fasta, fasta.gz, fasta.bz2, fasta.lzma.

    output:
    tuple val(meta), path("*.{stats,json}")            , emit: stats
    tuple val(meta), path("${prefix}.${output_format}"), emit: reads
    tuple val("${task.process}"), val('nanoq'), eval('nanoq --version | sed "s/nanoq //g"'), emit: versions_nanoq, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_filtered"
    if (output_format.startsWith('fasta')) {
        // nanoq (0.10.0) writes records in the INPUT format whatever the -o extension is
        // (verified: `-o x.fasta`, with or without -f, still emits FASTQ), so a "fasta" output
        // was FASTQ under a .fasta name and CheckV rejected it. Filter to FASTQ, then convert.
        def compress = output_format == 'fasta'    ? ''
                     : output_format == 'fasta.gz' ? '| gzip -c'
                     : null
        if (compress == null) {
            error "NANOQ: output_format '${output_format}' is not supported for FASTA (use fasta or fasta.gz)"
        }
        """
        nanoq -i ${ontreads} \\
            ${args} \\
            -r ${prefix}.stats \\
            -O u \\
            -o ${prefix}.tmp.fastq

        awk 'NR%4==1 { print ">" substr(\$0, 2) } NR%4==2 { print }' ${prefix}.tmp.fastq ${compress} > ${prefix}.${output_format}

        rm -f ${prefix}.tmp.fastq
        """
    } else {
        """
        nanoq -i ${ontreads} \\
            ${args} \\
            -r ${prefix}.stats \\
            -o ${prefix}.${output_format}
        """
    }

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    echo "" | gzip > ${prefix}.${output_format}
    touch ${prefix}.stats
    """
}
