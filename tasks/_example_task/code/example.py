#!/usr/bin/env python3
"""example.py — Skeleton Python script with argparse.

Usage:
    python code/example.py --input input/data.csv --output output/result.csv

This script demonstrates the pattern for production Python scripts:
    1. Parse command-line arguments (no hardcoded paths)
    2. Read from input/
    3. Process data
    4. Write to output/
"""

import argparse


def main():
    parser = argparse.ArgumentParser(description="Example processing script")
    parser.add_argument("--input", default="input/data.csv",
                        help="Path to input data file")
    parser.add_argument("--output", default="output/result.csv",
                        help="Path to output file")
    args = parser.parse_args()

    # --- Read input ---
    print(f"Reading input from: {args.input}")
    # import pandas as pd
    # data = pd.read_csv(args.input)

    # --- Process ---
    print("Processing data...")
    # result = data.groupby("group").agg({"value": "mean"})

    # --- Write output ---
    print(f"Writing output to: {args.output}")
    # result.to_csv(args.output, index=False)

    print("Done.")


if __name__ == "__main__":
    main()
