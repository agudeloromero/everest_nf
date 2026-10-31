#!/bin/bash
#ABC --name=everest-amr-gene
#ABC --namespace=su-everest-nf
#ABC --driver=docker
#ABC --driver.config.image=quay.io/biocontainers/abricate:1.0.1--ha8f3691_1
#ABC --cores=1
#ABC --mem=2G
# Print one NCBI AMR gene (blaTEM-1) from abricate's bundled ncbi db to the job log, to build
# a positive-control contig (lambda + this gene) for ABRICATE_RUN.
set -eu
python3 - /usr/local/db/ncbi/sequences <<'PY'
import sys
recs=[];h=None;s=[]
for l in open(sys.argv[1]):
    l=l.strip()
    if l.startswith('>'):
        if h: recs.append((h,''.join(s)))
        h=l;s=[]
    else: s.append(l)
recs.append((h,''.join(s)))
g=[r for r in recs if 'blaTEM-1' in r[0]][0]
print('===BEGIN===')
print(g[1])
print('===END===')
PY
