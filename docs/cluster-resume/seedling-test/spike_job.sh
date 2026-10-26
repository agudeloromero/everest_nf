#!/bin/bash
#ABC --name=everest-lambda-spike
#ABC --namespace=su-everest-nf
#ABC --driver=docker
#ABC --driver.config.image=python:3.12-slim
#ABC --cores=2
#ABC --mem=2G
# Build lambda-spiked EVEREST test reads. Inputs are staged by `abc job run --in`, outputs
# collected from ./out by `--out`. See make_lambda_spike.py for why the spike exists.
set -eu   # run under /bin/sh (dash) in the container: no pipefail
mkdir -p out
D=docs/cluster-resume/seedling-test   # local --in files keep their repo-relative path
G=$D/lambda_NC_001416.1.fasta
python3 $D/make_lambda_spike.py pe  --genome "$G" --depth 60 --prefix lam_pe  --seed 1
python3 $D/make_lambda_spike.py ont --genome "$G" --depth 40 --prefix lam_ont --seed 1
for s in ERR3274620 ERR3274626 SRR5110508 SRR5110531; do
  case $s in ERR*) p=PRJEB32062;; *) p=PRJNA316588;; esac
  for r in R1 R2; do
    cat "${s}_${r}.sub.fq.gz" "lam_pe_${r}.fq.gz" > "out/${p}__${s}_${r}.spike.fq.gz"
  done
done
cp lam_ont.fastq.gz out/LAMBDALR_R1.fastq.gz
ls -la out
