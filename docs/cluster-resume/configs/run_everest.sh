#!/usr/bin/bash

set -uex


# Patricia's token for tower.nf
export TOWER_ACCESS_TOKEN=<REDACTED>

# TKI/misc
export TOWER_WORKSPACE_ID=140696260610776

#export NXF_CLOUDCACHE_PATH="s3://acacia/temp/nxf_cache"

NAME="oci-aerial-t-everest-$RANDOM"

export NXF_CACHE_DIR="/home/opc/.nextflow/everest/"



nextflow run agudeloromero/everest_nf \
		 -c /home/opc/everest.config \
		 -name "$NAME" \
		 -profile docker \
		 -with-tower \
		 --outdir "/home/opc/results/everest-nf/$NAME" \
		 -params-file  "/home/opc/params.everest.new.yaml" \
		 -r develop \
		 -work-dir "/home/opc/work//everest-nf/$NAME" \
		 -resume \
		 -latest



#		 -params-file  "/home/p_agudeloromero/mysoftware/DB_everest/_params/test_SRPE_DNA_pass.yml" \
