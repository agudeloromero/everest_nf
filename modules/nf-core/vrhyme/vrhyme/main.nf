process VRHYME_VRHYME {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vrhyme:1.1.0--pyhdfd78af_1':
        'biocontainers/vrhyme:1.1.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(fasta), path(reads)

    output:
    tuple val(meta), path("**/vRhyme_best_bins_fasta/*.{fasta,ffn,faa}"), optional: true, emit: bins
    tuple val(meta), path("**/vRhyme_best_bins.*.membership.tsv")       , optional: true, emit: membership
    tuple val(meta), path("**/vRhyme_best_bins.*.summary.tsv")          , optional: true, emit: summary
    tuple val("${task.process}"), val('vrhyme'), eval('vRhyme --version 2>&1 | sed "s/^.*vRhyme v//; s/Using.*//"'), emit: versions_vrhyme, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fasta_input = fasta.toString().replaceAll(/\.gz$/, '')
    def gunzip      = fasta.getExtension() == "gz" ? "gunzip -c ${fasta} > ${fasta_input}" : ""
    def cleanup     = fasta.getExtension() == "gz" ? "rm ${fasta_input}" : ""
    """
    ${gunzip}

    # vRhyme refuses to run with fewer than 2 scaffolds of at least the minimum length
    # (default 2000 bp, -l) and exits 1. Binning needs >=2 scaffolds, so that is "nothing to
    # bin" rather than a failure: skip cleanly and emit no bins. Clear any output folder left
    # by an earlier attempt, since vRhyme also refuses to write into an existing -o folder.
    rm -rf $prefix
    n_scaffolds=\$(awk '/^>/ { if (len >= 2000) n++; len = 0; next } { len += length(\$0) } END { if (len >= 2000) n++; print n + 0 }' $fasta_input)
    if [ "\$n_scaffolds" -lt 2 ]; then
        echo "vRhyme skipped: \$n_scaffolds scaffold(s) >= 2000 bp (needs at least 2)" >&2
    else
        vRhyme \\
            -i $fasta_input \\
            -r $reads \\
            -o $prefix \\
            -t $task.cpus \\
            $args
    fi

    #mv $prefix/vRhyme_best_bins_fasta/ vRhyme_best_bins_fasta

    ${cleanup}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p $prefix
    touch $prefix/vRhyme_best_bins.19.membership.tsv
    touch $prefix/vRhyme_best_bins.19.summary.tsv
    mkdir -p $prefix/vRhyme_best_bins_fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_1.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_10.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_11.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_12.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_13.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_14.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_2.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_3.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_4.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_5.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_6.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_7.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_8.fasta
    touch $prefix/vRhyme_best_bins_fasta/vRhyme_bin_9.fasta
    """
}
