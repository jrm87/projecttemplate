#!/bin/bash
#SBATCH --job-name=example_task
#SBATCH --partition=common
#SBATCH --time=04:00:00
#SBATCH --mem=100G
#SBATCH --cpus-per-task=4
#SBATCH --output=slurm_logs/%j.out
#SBATCH --error=slurm_logs/%j.err

# --- CUSTOMIZE: Choose ONE execution method below ---

# Option A: Container execution (DCC)
# REPO_ROOT=$(git rev-parse --show-toplevel)
# IMG=/opt/apps/containers/community/YOUR_USER/YOUR_PROJECT.sif
# singularity exec --pwd "$PWD" \
#   --bind "$REPO_ROOT:$REPO_ROOT" "$IMG" \
#   Rscript code/example.R --input input/data.csv --output output/result.csv

# Option B: Conda execution (TACC)
# source /work/<PROJECT_NUM>/<USER>/ls6/miniconda3/etc/profile.d/conda.sh
# conda activate my_env
# python code/example.py --input input/data.csv --output output/result.csv

echo "Job completed: $(date)"
