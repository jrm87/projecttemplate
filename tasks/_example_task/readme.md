# Task: _example_task

<!-- CUSTOMIZE: Replace with your task description -->

## Purpose

This is a template task demonstrating all common patterns. Copy it to
create a new task:

```bash
cp -r tasks/_example_task tasks/my_new_task
```

## Inputs

<!-- List all input files with their upstream source -->
| File | Source Task | Description |
|------|-----------|-------------|
| `input/upstream_data.csv` | `upstream_task` | Description of this input |

## Outputs

<!-- List all output files -->
| File | Description |
|------|-------------|
| `output/result.csv` | Description of this output |

## Code

| Script | Description |
|--------|-------------|
| `code/example.R` | Main processing script (R with optparse) |
| `code/example.py` | Alternative Python script (with argparse) |
| `code/example.slurm` | SLURM job script for HPC execution |

## Dependencies

- **Upstream:** `upstream_task`
- **Downstream:** tasks that symlink to `output/result.csv`

## Computational Requirements

- **Time:** ~1 hour
- **Memory:** ~10 GB
- **CPU:** 4 cores
- **GPU:** No
