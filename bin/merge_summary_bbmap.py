#!/usr/bin/env python3

import pandas as pd
import glob
import os
import argparse

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description="Merge bbmap_stats with nt and aa summary files by shared base name.")
parser.add_argument("path1", help="Path to folder containing *_bbmap_stats.txt files")
parser.add_argument("path2", help="Path to folder containing *_summary_nt.txt and *_summary_aa.txt files")
args = parser.parse_args()

path1 = args.path1
path2 = args.path2

# Minimal column set so an all-empty (no-taxonomy) sample still yields a file
# downstream (update_taxonomic_rank_manual.py) can parse.
MINIMAL_SUMMARY_COLS = [
    'lca_query', 'lca_taxname', 'lca_taxonomic_rank',
    'lca_kingdom', 'lca_phylum', 'lca_class', 'lca_order',
    'lca_family', 'lca_genus', 'lca_species',
]

# Get all relevant files
bbmap_files = glob.glob(os.path.join(path1, "*_bbmap_stats.txt"))
nt_files = glob.glob(os.path.join(path2, "*_summary_nt.txt"))
aa_files = glob.glob(os.path.join(path2, "*_summary_aa.txt"))

# Map base names to file paths
bbmap_dict = {os.path.basename(f).replace("_bbmap_stats.txt", ""): f for f in bbmap_files}
nt_dict = {os.path.basename(f).replace("_summary_nt.txt", ""): f for f in nt_files}
aa_dict = {os.path.basename(f).replace("_summary_aa.txt", ""): f for f in aa_files}


def header_cols(path):
    """Return a TSV's column names, or None if the file is empty/unreadable."""
    try:
        return list(pd.read_csv(path, sep='\t', nrows=0).columns)
    except Exception:
        return None


def read_summary(path, fallback_cols):
    """Read a summary TSV. If it is empty (e.g. a sample with no taxonomy hits),
    return a 0-row frame with the sibling mode's columns (NT and AA share the same
    schema) so the merge still produces a valid, parseable output file instead of
    crashing the whole pipeline on a missing output."""
    try:
        return pd.read_csv(path, sep='\t')
    except pd.errors.EmptyDataError:
        cols = list(fallback_cols) if fallback_cols else list(MINIMAL_SUMMARY_COLS)
        if 'lca_query' not in cols:
            cols = ['lca_query'] + cols
        return pd.DataFrame(columns=cols)


# Sibling header columns, used as a fallback schema when one mode is empty
nt_cols = {b: header_cols(p) for b, p in nt_dict.items()}
aa_cols = {b: header_cols(p) for b, p in aa_dict.items()}

# Merge nt files
for base in set(bbmap_dict.keys()) & set(nt_dict.keys()):
    try:
        df_bbmap = pd.read_csv(bbmap_dict[base], sep='\t')
        df_nt = read_summary(nt_dict[base], aa_cols.get(base))
        merged_nt = pd.merge(df_nt, df_bbmap, left_on='lca_query', right_on='Name', how='inner')
        output_nt = os.path.join(path2, f"{base}_nt_summary_mmseqs2_stats.txt")
        merged_nt.to_csv(output_nt, sep='\t', index=False)
        print(f"Merged and saved NT: {output_nt} ({len(merged_nt)} rows)")
    except Exception as e:
        print(f"Error merging NT for {base}: {e}")

# Merge aa files (symmetric; borrows the NT schema when the AA summary is empty)
for base in set(bbmap_dict.keys()) & set(aa_dict.keys()):
    try:
        df_bbmap = pd.read_csv(bbmap_dict[base], sep='\t')
        df_aa = read_summary(aa_dict[base], nt_cols.get(base))
        merged_aa = pd.merge(df_aa, df_bbmap, left_on='lca_query', right_on='Name', how='inner')
        output_aa = os.path.join(path2, f"{base}_aa_summary_mmseqs2_stats.txt")
        merged_aa.to_csv(output_aa, sep='\t', index=False)
        print(f"Merged and saved AA: {output_aa} ({len(merged_aa)} rows)")
    except Exception as e:
        print(f"Error merging AA for {base}: {e}")
