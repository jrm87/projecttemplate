# Task Workflow: Reports vs Production Code

## The Problem

Researchers often iterate quickly using Quarto/RMarkdown notebooks
that combine code, output, and narrative. These are excellent for
sharing results with collaborators. However, when the code in these
notebooks produces outputs that the paper or other tasks depend on,
the notebook becomes de facto production code — but without the
reproducibility, modularity, and dependency tracking that the
task-based pipeline provides.

## The Rule

**Quarto reports are for communication. Standalone scripts are for
production.**

A report file (`.qmd`, `.Rmd`) should be a **consumer** of task
outputs, not a **producer** of them. It reads from `input/` and
generates a human-readable report (PDF/HTML). If the code inside a
report computes something that other tasks or the paper need, that
computation must be extracted into a standalone script in the
appropriate task's `code/` directory.

## Two Types of Code

### 1. Production code (`code/*.R`, `code/*.py`, `code/*.do`)

- Lives in a task's `code/` directory
- Has a corresponding Makefile target
- Reads from `input/`, writes to `output/`
- No narrative, no plots for humans — just data transformation
- Can be run non-interactively: `Rscript code/script.R --args`
- Must use relative paths or command-line arguments (no hardcoded paths)
- Outputs are consumed by downstream tasks via symlinks

### 2. Report code (`code/*.qmd` or `reports/*.qmd`)

- Generates a report (PDF/HTML) for the team
- Reads from `input/` (symlinked from upstream task outputs)
- May produce tables/figures for the paper as a side effect
- Can be committed to the repo for timestamping
- Does NOT produce intermediate data that other tasks depend on
- If a report computes something useful, that code graduates
  to a production script (see below)

## The Graduation Process

When code in a report needs to become production code:

1. **Identify the computation.** What chunk(s) produce outputs
   that other tasks or the paper need?

2. **Extract into a standalone script.** Move the relevant code
   into `code/<descriptive_name>.R` (or `.py`). The script should:
   - Accept input/output paths as command-line arguments
     (use `optparse` in R, `argparse` in Python)
   - Read from `input/` via paths passed as arguments
   - Write to `output/` via paths passed as arguments
   - Not require any interactive input or IDE

3. **Add a Makefile target.** Wire the new script into the task's
   Makefile with proper input dependencies.

4. **Update the report.** The report should now READ the production
   script's output from `input/` rather than computing it inline.

5. **Commit both.** Use `feat:` prefix for the production script,
   `report:` for the updated report.

## Sentinel File Pattern for Multi-Output Rules

GNU Make < 4.3 treats `a b: deps` as TWO separate rules with the
SAME recipe, running it once per target (= duplicate SLURM jobs).

```makefile
# WRONG — submits two SLURM jobs:
output/params.rds output/beliefs.csv: code/script.R
	$(call RSCRIPT,code/script.R)

# RIGHT — submits one job:
output/.step_done: code/script.R
	$(call RSCRIPT,code/script.R)
	touch $@
output/params.rds: output/.step_done
output/beliefs.csv: output/.step_done
```

Name sentinels `output/.<step>_done`. The `clean` target's
`rm -rf output/` removes them automatically.

## Container Policy

<!-- CUSTOMIZE: Adjust for your project's setup -->

- **R on DCC**: runs in the Singularity container via `RSCRIPT`/`RUN_CMD`.
- **R on TACC**: runs via conda environment.
- **Python**: always via conda environment on both clusters.
- **Stata**: runs directly (no container needed).
- **User-library packages** (`~/R/...`) are a temporary workaround.
  Once the container is rebuilt with the package, remove user-library copies.

## What the PR/CI Checks Enforce

1. No hardcoded user paths in production scripts.
2. No `setwd()` in R.
3. No multi-output rules without sentinel files.
4. Production scripts should have Makefile targets (warning).
5. Reports should not do heavy computation (warning, >50 lines).
