#!/usr/bin/env python3

import pandas as pd
import glob
import os
import argparse

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description="Process and merge BBMap *_rpkm.txt and *_covstats.txt files in a specified folder.")
parser.add_argument("folder", help="Path to the folder containing the BBMap output files")
args = parser.parse_args()

folder = args.folder

# --- Step 1: Process *_rpkm.txt files ---
rpkm_columns_to_keep = ['Name', 'Length', 'Bases', 'Coverage', 'Reads', 'RPKM']
rpkm_files = glob.glob(os.path.join(folder, "*_rpkm.txt"))

rpkm_data = {}  # base_name -> DataFrame

for file in rpkm_files:
    try:
        df = pd.read_csv(file, sep='\t', skiprows=4, comment=None)
        df.columns = [col.lstrip('#') for col in df.columns]
        df = df[[col for col in df.columns if col in rpkm_columns_to_keep]]

        base_name = os.path.basename(file).replace("_contig", "").replace("_rpkm.txt", "")
        rpkm_data[base_name] = df
        print(f"Loaded RPKM: {file}")
    except Exception as e:
        print(f"Error processing RPKM file {file}: {e}")

# --- Step 2: Process *_covstats.txt files ---
covstats_columns_to_keep = ['ID', 'Ref_GC']
covstats_files = glob.glob(os.path.join(folder, "*_covstats.txt"))

covstats_data = {}  # base_name -> DataFrame

for file in covstats_files:
    try:
        df = pd.read_csv(file, sep='\t', comment=None)
        df.columns = [col.lstrip('#') for col in df.columns]
        df = df[[col for col in df.columns if col in covstats_columns_to_keep]]
        df = df.rename(columns={'Ref_GC': 'GC'})

        base_name = os.path.basename(file).replace("_contig", "").replace("_covstats.txt", "")
        covstats_data[base_name] = df
        print(f"Loaded Covstats: {file}")
    except Exception as e:
        print(f"Error processing Covstats file {file}: {e}")

# --- Step 3: Merge and save ---
final_columns = ['Name', 'Length', 'Bases', 'Coverage', 'Reads', 'RPKM', 'GC']
common_bases = set(rpkm_data.keys()) & set(covstats_data.keys())

total_merged = 0
for base in common_bases:
    try:
        merged_df = pd.merge(rpkm_data[base], covstats_data[base], left_on='Name', right_on='ID', how='inner')
        merged_df = merged_df[final_columns]

        output_file = os.path.join(folder, f"{base}_bbmap_stats.txt")
        merged_df.to_csv(output_file, sep='\t', index=False)
        print(f"Merged and saved: {output_file}")

        total_merged += 1
    except Exception as e:
        print(f"Error merging {base}: {e}")

if total_merged == 0:
    print("No matching file pairs found to merge.")
else:
    print(f"Successfully merged {total_merged} file pairs.")
