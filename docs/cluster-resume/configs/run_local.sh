#!/usr/bin/bash

set -ue


# Patricia's token for tower.nf
export TOWER_ACCESS_TOKEN=<REDACTED>

# TKI/everest
export TOWER_WORKSPACE_ID=478173705272


#export NXF_CLOUDCACHE_PATH="s3://acacia/temp/nxf_cache"

NAME="dev-rid$RANDOM"

export NXF_CACHE_DIR="/home/opc/EVEREST/.nextflow/everest/"



nextflow run everest_nf \
		 -c /home/opc/EVEREST/everest.config \
		 -name "$NAME" \
		 -profile test,docker \
		 -with-tower \
		 -resume \
		 -params-file  "/home/opc/EVEREST/params.data_test.yaml" \
		 -work-dir "/home/opc/EVEREST/_deleteme/work/" \
		 -dump-channels "ch_reads_branched.contigs" \
		 --outdir "/home/opc/EVEREST/results/_deleteme/outdir/$NAME"


#		 -dump-channels \
#		 -params-file  "/home/p_agudeloromero/mysoftware/DB_everest/_params/test_SRPE_DNA_pass.yml" \
