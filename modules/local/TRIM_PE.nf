process TRIM_PE{
		tag "$meta.id"
		label 'process_medium'

		conda (params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

		input:
		tuple val(meta), path('*_clean_R1.fastq.gz')	, emit: clean1
		tuple val(meta), path('*_clean_R1.fastq.gz')	, emit: clean2
		path adapters
		
		output:
		tuple val(meta), path('*_trimm_pair_R1.fastq.gz')	, emit: p1
		tuple val(meta), path('*_trimm_unpair_R1.fastq.gz')	, emit: up1
		tuple val(meta), path('*_trimm_pair_R2.fastq.gz')	, emit: p2
		tuple val(meta), path('*_trimm_unpair_R2.fastq.gz')	, emit: up2
		tuple val(meta), path('*.log')						, emit: log
		path "versions.yml"									, emit: versions

		script:
		def args = task.ext.args ?: '-7'
		def prefix = task.ext.prefix ?: "${meta.id}"
		"""
		trimmomatic PE \\
		-threads $args \
		-phred33 \\
		$clean1 $clean2 \\
		$p1 $up1 \\
		$p2 $up2 \\
		ILLUMINACLIP:$adaptors:2:30:10 \\
		> ${prefix}.TRIM_PE.log

		cat <<-END_VERSIONS > versions.yml
		"${task.process}":
			TRIM_PE: \$(trimmomatic --version)
		END_VERSIONS
		"""
}
