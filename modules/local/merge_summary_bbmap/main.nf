process MERGE_SUMMARY_BBMAP {
    tag "${task.ext.prefix ?: 'merge_summary_bbmap'}"
    label 'process_low'
    stageInMode 'copy'

    conda { params.conda_python3_env }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://quay.io/biocontainers/pandas:1.5.2' :
        'quay.io/biocontainers/pandas:1.5.2' }"

    input:
    path(bbmap_stats_files)
    path(summary_files)

    output:
    path("summary/*_nt_summary_mmseqs2_stats.txt") , emit: nt_stats
    path("summary/*_aa_summary_mmseqs2_stats.txt") , emit: aa_stats
    path("versions.yml")                           , emit: versions

    script:
    """
    mkdir -p bbmap summary

    shopt -s nullglob
    for file in *_bbmap_stats.txt; do
        mv "\$file" bbmap/
    done
    for file in *_summary_nt.txt *_summary_aa.txt; do
        if [[ -e "\$file" ]]; then
            mv "\$file" summary/
        fi
    done

    merge_summary_bbmap.py bbmap summary

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p summary
    touch summary/test_nt_summary_mmseqs2_stats.txt
    touch summary/test_aa_summary_mmseqs2_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """
}