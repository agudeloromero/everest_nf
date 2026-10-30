#!/usr/bin/env python3

import pandas as pd
import glob
import os
import argparse

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description="Update taxonomy rank for mmseqs2 stats files.")
parser.add_argument("folder", help="Path to the folder containing *_summary_mmseqs2_stats.txt files")
args = parser.parse_args()

folder = args.folder

# Define mapping of lineage columns to rank names (right to left)
rank_columns = [
    ('lca_species', 'species'),
    ('lca_genus', 'genus'),
    ('lca_family', 'family'),
    ('lca_order', 'order'),
    ('lca_class', 'class'),
    ('lca_phylum', 'phylum'),
    ('lca_kingdom', 'kingdom')
]

# Find all relevant files
files = glob.glob(os.path.join(folder, "*_nt_summary_mmseqs2_stats.txt")) + \
        glob.glob(os.path.join(folder, "*_aa_summary_mmseqs2_stats.txt"))

# Process each file
for file in files:
    try:
        df = pd.read_csv(file, sep='\t')

        # Determine insertion index for new column
        rank_index = df.columns.get_loc('lca_taxonomic_rank') + 1

        # Copy original rank to manual rank column
        df.insert(rank_index, 'lca_taxonomic_rank_manual', df['lca_taxonomic_rank'])

        # Update 'no rank' entries in the manual column
        for idx, row in df.iterrows():
            if row['lca_taxonomic_rank_manual'] == 'no rank':
                assigned = 'no rank'
                for col, rank_name in rank_columns:
                    if pd.notnull(row[col]) and 'unclassified' not in str(row[col]):
                        assigned = rank_name
                        break
                df.at[idx, 'lca_taxonomic_rank_manual'] = assigned

        # Create new filename
        new_filename = file.replace("_stats.txt", "_stats_taxrank.txt")
        df.to_csv(new_filename, sep='\t', index=False)
        print(f"Updated and saved: {new_filename}")

        # Delete original file
        os.remove(file)
        print(f"Deleted original file: {file}")

    except Exception as e:
        print(f"Error processing {file}: {e}")
