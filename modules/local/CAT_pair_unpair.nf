process CAT_pair_unpair{
		tag "$meta.id"
		label 'process_medium'

//		conda (params.enable_conda ? 'bioconda::trimmomatic=0.39' : null)

		input:
		tuple val(meta), path('*_trimm_pair_R1.fastq.gz')	, emit: p1
		tuple val(meta), path('*_trimm_unpair_R1.fastq.gz')	, emit: up1
		tuple val(meta), path('*_trimm_pair_R2.fastq.gz')	, emit: p2
		tuple val(meta), path('*_trimm_unpair_R2.fastq.gz')	, emit: up2
		
		output:
		tuple val(meta), path('*_trimm_cat_R1.fastq.gz')	, emit: c1
		tuple val(meta), path('*_trimm_cat_R2.fastq.gz')	, emit: c2
		tuple val(meta), path('*.log')						, emit: log
		path "versions.yml"									, emit: versions

		script:
//		def args = task.ext.args ?: '-7'
		def prefix = task.ext.prefix ?: "${meta.id}"
		"""
		cat $p1 $up1 > $c1 ;\\
		cat $p2 $.up2 > $c2 \\
		> ${prefix}.CAT.pair_unpair.log

		cat <<-END_VERSIONS > versions.yml
		"${task.process}":
//			CAT_pair_unpair: \$(trimmomatic --version)
		END_VERSIONS
		"""
}
