#!/usr/bin/bash

set -ue

# Patricia's token for tower.nf
export TOWER_ACCESS_TOKEN=<REDACTED>

# TKI/everest
export TOWER_WORKSPACE_ID=478173705272

#export NXF_CLOUDCACHE_PATH="s3://acacia/temp/nxf_cache"

NAME="oci-dev-rid$RANDOM"

export NXF_CACHE_DIR="/home/opc/EVEREST/.nextflow/everest/"


nextflow run agudeloromero/everest_nf \
		 -c /home/opc/EVEREST/everest.config \
		 -name "$NAME" \
		 -profile docker \
		 -with-tower \
		 --outdir "/home/opc/EVEREST/_deleteme/results/$NAME" \
		 -params-file  "/home/opc/EVEREST/params.data_test.yaml" \
		 -r vrhyme-summaries \
		 -work-dir "/home/opc/EVEREST/work/" \
		 -resume \
		 -latest



#		 -dump-channels "ch_spades_input"
#		 -params-file  "/home/p_agudeloromero/mysoftware/DB_everest/_params/test_SRPE_DNA_pass.yml" \
