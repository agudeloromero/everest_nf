#!/usr/bin/env python3

import pandas as pd
import glob
import os
import argparse

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description="Combine all *_nt_summary_mmseqs2_stats_taxrank.txt and *_aa_summary_mmseqs2_stats_taxrank.txt files into final EVEREST summaries. Output files are saved in the same folder.")
parser.add_argument("folder", help="Path to the folder containing the taxrank files (output will also be saved here)")
args = parser.parse_args()

folder = args.folder

# --- Combine NT files ---
nt_files = glob.glob(os.path.join(folder, "*_nt_summary_mmseqs2_stats_taxrank.txt"))

if nt_files:
    try:
        nt_dfs = []
        for file in nt_files:
            df = pd.read_csv(file, sep='\t')
            nt_dfs.append(df)
            print(f"Loaded NT file: {file}")
        nt_combined = pd.concat(nt_dfs, ignore_index=True)
        nt_output = os.path.join(folder, "EVEREST_nt_summary.txt")
        nt_combined.to_csv(nt_output, sep='\t', index=False)
        print(f"\nSaved combined NT summary: {nt_output}")
        print(f"  -> {len(nt_files)} samples merged | {len(nt_combined)} total rows")
    except Exception as e:
        print(f"Error combining NT files: {e}")
else:
    print("No *_nt_summary_mmseqs2_stats_taxrank.txt files found.")

# --- Combine AA files ---
aa_files = glob.glob(os.path.join(folder, "*_aa_summary_mmseqs2_stats_taxrank.txt"))

if aa_files:
    try:
        aa_dfs = []
        for file in aa_files:
            df = pd.read_csv(file, sep='\t')
            aa_dfs.append(df)
            print(f"Loaded AA file: {file}")
        aa_combined = pd.concat(aa_dfs, ignore_index=True)
        aa_output = os.path.join(folder, "EVEREST_aa_summary.txt")
        aa_combined.to_csv(aa_output, sep='\t', index=False)
        print(f"\nSaved combined AA summary: {aa_output}")
        print(f"  -> {len(aa_files)} samples merged | {len(aa_combined)} total rows")
    except Exception as e:
        print(f"Error combining AA files: {e}")
else:
    print("No *_aa_summary_mmseqs2_stats_taxrank.txt files found.")
