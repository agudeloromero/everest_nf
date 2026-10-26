#!/usr/bin/env python3
"""Simulate phage lambda (NC_001416.1) reads to spike the subsampled EVEREST test data.

Why: the subsampled virome reads (PRJEB32062 / PRJNA316588) are human-dominated, so host
removal + dedup + normalisation leave an EMPTY SPAdes assembly and mmseqs dies on empty input.
Lambda is non-human (survives host removal), non-phiX (survives BBMAP_PHIX) and assembles into a
clean ~48.5 kb contig even if every real read is removed. Quality strings are varied (not
constant) so SPAdes BayesHammer can detect the Phred offset.

Stdlib only. Examples:
  make_lambda_spike.py pe  --genome lambda.fa --depth 60 --prefix out/lambda_pe --seed 1
      -> out/lambda_pe_R1.fq.gz, out/lambda_pe_R2.fq.gz
  make_lambda_spike.py ont --genome lambda.fa --depth 40 --prefix out/lambda_ont --seed 1
      -> out/lambda_ont.fastq.gz
gzip members can be concatenated, so `cat real.sub.fq.gz lambda_pe_R1.fq.gz > sample_R1.spike.fq.gz`
yields a valid spiked file.
"""
import argparse
import gzip
import math
import random

COMP = str.maketrans("ACGTacgt", "TGCAtgca")


def read_fasta(path):
    seq = []
    with open(path) as fh:
        for line in fh:
            if not line.startswith(">"):
                seq.append(line.strip().upper())
    return "".join(seq)


def revcomp(s):
    return s.translate(COMP)[::-1]


def mutate(seq, rng, sub, ins, dele):
    out = []
    for b in seq:
        r = rng.random()
        if r < dele:
            continue
        if r < dele + sub:
            out.append(rng.choice([x for x in "ACGT" if x != b]))
        else:
            out.append(b)
        if rng.random() < ins:
            out.append(rng.choice("ACGT"))
    return "".join(out)


def illumina_quals(n, rng):
    q = []
    for i in range(n):
        base = 37 - 8 * (i / n) ** 2          # mild 3' decay
        q.append(max(2, min(41, int(rng.gauss(base, 3)))))
    return q


def simulate_pe(genome, depth, rng, rlen=150, ins_mean=350, ins_sd=30):
    pairs = int(depth * len(genome) / (2 * rlen))
    for i in range(pairs):
        frag = max(rlen + 10, int(rng.gauss(ins_mean, ins_sd)))
        frag = min(frag, len(genome))
        start = rng.randrange(0, len(genome) - frag + 1)
        f = genome[start:start + frag]
        r1, r2 = f[:rlen], revcomp(f)[:rlen]
        if rng.random() < 0.5:
            r1, r2 = r2, r1
        recs = []
        for r in (r1, r2):
            q = illumina_quals(len(r), rng)
            bases = list(r)
            for j, qq in enumerate(q):               # error ~ 10^(-Q/10)
                if rng.random() < 10 ** (-qq / 10):
                    bases[j] = rng.choice([x for x in "ACGT" if x != bases[j]])
            recs.append(("".join(bases), "".join(chr(33 + x) for x in q)))
        yield i, recs


def simulate_ont(genome, depth, rng, mean_len=4000):
    total, i = 0, 0
    target = depth * len(genome)
    while total < target:
        ln = int(min(len(genome), max(500, rng.lognormvariate(math.log(mean_len), 0.5))))
        start = rng.randrange(0, len(genome) - ln + 1)
        frag = genome[start:start + ln]
        if rng.random() < 0.5:
            frag = revcomp(frag)
        frag = mutate(frag, rng, sub=0.03, ins=0.015, dele=0.015)   # ~6% error
        qual = "".join(chr(33 + max(3, min(30, int(rng.gauss(13, 3))))) for _ in frag)
        yield i, frag, qual
        total += len(frag)
        i += 1


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["pe", "ont"])
    ap.add_argument("--genome", required=True)
    ap.add_argument("--depth", type=float, required=True)
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--seed", type=int, default=1)
    a = ap.parse_args()
    rng = random.Random(a.seed)
    g = read_fasta(a.genome)
    if a.mode == "pe":
        with gzip.open(a.prefix + "_R1.fq.gz", "wt") as o1, gzip.open(a.prefix + "_R2.fq.gz", "wt") as o2:
            n = 0
            for i, ((s1, q1), (s2, q2)) in simulate_pe(g, a.depth, rng):
                o1.write(f"@LAMBDA_{i}/1\n{s1}\n+\n{q1}\n")
                o2.write(f"@LAMBDA_{i}/2\n{s2}\n+\n{q2}\n")
                n += 1
        print(f"wrote {n} read pairs ({a.depth}x of {len(g)} bp)")
    else:
        with gzip.open(a.prefix + ".fastq.gz", "wt") as o:
            n = 0
            for i, s, q in simulate_ont(g, a.depth, rng):
                o.write(f"@LAMBDA_LR_{i}\n{s}\n+\n{q}\n")
                n += 1
        print(f"wrote {n} long reads ({a.depth}x of {len(g)} bp)")


if __name__ == "__main__":
    main()
