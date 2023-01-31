process BBMAP_phix{
		tag "$meta.id"
		label 'process_medium'

		conda (params.enable_conda ? 'bioconda::bbmap=38.96' : null)

		input:
		tuple val(meta), path(reads)
		path adapters

		output:
		tuple val(meta), path('*_clean_R1.fastq.gz')	, emit: clean1
		tuple val(meta), path('*_clean_R2.fastq.gz')	, emit: clean2
		tuple val(meta), path('*_noclean_R1.fastq.gz')	, emit: unclean1
		tuple val(meta), path('*_noclean_R2.fastq.gz')	, emit: unclean2
		tuple val(meta), path('*_stats_phix.txt')		, emit: stats_phix
		tuple val(meta), path('*.log')					, emit: log
		path "versions.yml"								, emit: versions

		script:
		def args = task.ext.args ?: '-Xmx20000m'
		def args2 = task.ext.args ?: 'ordered cardinality k=31 hdist=1'
		def prefix = task.ext.prefix ?: "${meta.id}"
		"""
		bbduk.sh \\
			--cores $task.cpus \\ // do I need this?
			$args \\
			in1=$reads in2=$reads \\ // I don't know how to call R1 + R2
			out1=$clean1 out2=$clean2 \\
			outm1=$unclean1 outm2=$unclean2 \\
			ref=artifacts,phix \\
			stats=$stats_phix \\
			$arg2 \\
			> ${prefix}.bbmap_phix.log

		cat <<-END_VERSIONS > versions.yml
		"${task.process}":
			BBMAP_phix: \$(bbmap --version)
		END_VERSIONS
		"""
}
