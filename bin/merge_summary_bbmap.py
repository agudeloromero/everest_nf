#!/usr/bin/env python3

import pandas as pd
import glob
import os
import argparse

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description="Merge bbmap_stats with nt and aa summary files by shared base name.")
parser.add_argument("path1", help="Path to folder containing *_bbmap_stats.txt files")
parser.add_argument("path2", help="Path to folder containing *_nt_summary_mmseqs2.txt and *_aa_summary_mmseqs2.txt files")
args = parser.parse_args()

path1 = args.path1
path2 = args.path2

# Get all relevant files
bbmap_files = glob.glob(os.path.join(path1, "*_bbmap_stats.txt"))
nt_files = glob.glob(os.path.join(path2, "*_nt_summary_mmseqs2.txt"))
aa_files = glob.glob(os.path.join(path2, "*_aa_summary_mmseqs2.txt"))

# Map base names to file paths
bbmap_dict = {os.path.basename(f).replace("_bbmap_stats.txt", ""): f for f in bbmap_files}
nt_dict = {os.path.basename(f).replace("_nt_summary_mmseqs2.txt", ""): f for f in nt_files}
aa_dict = {os.path.basename(f).replace("_aa_summary_mmseqs2.txt", ""): f for f in aa_files}

# Merge nt files
for base in set(bbmap_dict.keys()) & set(nt_dict.keys()):
    try:
        df_bbmap = pd.read_csv(bbmap_dict[base], sep='\t')
        df_nt = pd.read_csv(nt_dict[base], sep='\t')
        merged_nt = pd.merge(df_nt, df_bbmap, left_on='lca_query', right_on='Name', how='inner')
        output_nt = os.path.join(path2, f"{base}_nt_summary_mmseqs2_stats.txt")
        merged_nt.to_csv(output_nt, sep='\t', index=False)
        print(f"Merged and saved NT: {output_nt}")
    except Exception as e:
        print(f"Error merging NT for {base}: {e}")

# Merge aa files
for base in set(bbmap_dict.keys()) & set(aa_dict.keys()):
    try:
        df_bbmap = pd.read_csv(bbmap_dict[base], sep='\t')
        df_aa = pd.read_csv(aa_dict[base], sep='\t')
        merged_aa = pd.merge(df_aa, df_bbmap, left_on='lca_query', right_on='Name', how='inner')
        output_aa = os.path.join(path2, f"{base}_aa_summary_mmseqs2_stats.txt")
        merged_aa.to_csv(output_aa, sep='\t', index=False)
        print(f"Merged and saved AA: {output_aa}")
    except Exception as e:
        print(f"Error merging AA for {base}: {e}")

