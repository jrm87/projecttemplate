# Project Template — CLAUDE.md

<!-- CUSTOMIZE: Replace this section with your project description -->
## Project Overview

This is a research project template implementing a **task-based pipeline
architecture** with Make-driven dependency management, SLURM cluster
integration (DCC + TACC), and an agentic workflow using Claude Code.

**Authors:** <!-- CUSTOMIZE: Your name(s) and affiliations -->
**Status:** <!-- CUSTOMIZE: e.g., "Data collection", "Estimation", "Paper draft" -->

## Repository Structure

```
├── CLAUDE.md              # This file — project knowledge base
├── Makefile               # Root Makefile (generates README.md)
├── tasks/                 # Analysis pipeline (one folder per task)
│   ├── generic.make       # Shared Makefile infrastructure
│   ├── slurm_helpers.sh   # SLURM job dependency utilities
│   ├── WORKFLOW.md        # Reports vs production code policy
│   ├── makefile_instructions.md  # How to write task Makefiles
│   ├── _example_task/     # Annotated skeleton task
│   ├── check_makefiles/   # CI: validate Makefiles
│   ├── task_graph/        # Generate dependency visualization
│   └── permissions/       # Fix HPC file permissions
├── paper/                 # LaTeX paper (pdflatex + bibtex)
├── slides/                # Beamer slides
├── logbook/               # Research logbook (tectonic)
├── container/             # Apptainer/Singularity definition
└── .claude/commands/      # Claude Code skills (/review-plan, /done, etc.)
```

## Languages & Tools

- **R** (primary), **Python**, **Stata** — analysis languages
- **GNU Make** — build orchestration and dependency management
- **SLURM** — HPC job scheduling (DCC at Duke, TACC at UT Austin)
- **Singularity/Apptainer** — containerized R environment on HPC
- **Conda** — Python environments; R environments on TACC
- **LaTeX** — paper, slides, logbook (pdflatex, tectonic)
- **Git + GitHub Actions** — version control and CI/CD

## Build & Run

### Local execution
```bash
make -C tasks/<task_name>           # Run a task locally
make -C tasks/<task_name> status    # Check output files
```

### HPC execution (DCC or TACC)
```bash
make -C tasks/<task_name>                  # Auto-detects HPC, submits via sbatch
make -C tasks/<task_name> INTERACTIVE=1    # Run via srun (blocks until done)
make -C tasks/<task_name> IS_TACC=0        # Force local mode on HPC
```

Environment auto-detection in `generic.make`:
- `IS_TACC=1` when `TACC_SYSTEM` env var is set or `sbatch` is in PATH
- `IS_DCC=1` when `SLURM_CLUSTER_NAME=dcc`
- `IS_HPC=1` when either cluster is detected

## Task Directory Convention

A **task** is a quantum of workflow defined by its input-output boundary.
Each task is a self-contained folder:

```
tasks/<task_name>/
├── Makefile       # Build rules; includes ../generic.make
├── readme.md      # Purpose, inputs, outputs, dependencies
├── code/          # Scripts (.R, .py, .do, .slurm)
├── input/         # Symlinks to upstream task outputs (gitignored)
├── output/        # Results for downstream tasks (gitignored)
├── temp/          # Intermediate files (gitignored)
├── .jobids/       # SLURM job ID tracking (gitignored)
└── slurm_logs/    # SLURM stdout/stderr (gitignored)
```

### Symlink system

Dependencies between tasks use symbolic links. A task's `input/` contains
symlinks pointing to upstream tasks' `output/` directories:

```makefile
input/upstream_file.csv: ../upstream_task/output/upstream_file.csv | input
	ln -sf $(abspath $<) $@
```

Key properties:
- Uses `$(abspath $<)` for machine-specific absolute paths
- `input/` directories are **gitignored** — recreated by `make`
- The generic recipe `../%` in `generic.make` auto-builds upstream tasks
- After syncing data from a cluster, run `make` to recreate local symlinks

## Generic.make Reference

All task Makefiles should `include ../generic.make`. It provides:

| Target/Variable | Description |
|----------------|-------------|
| `input output temp ...` | Directory creation rules |
| `../%` | Upstream dependency auto-resolution |
| `IS_TACC`, `IS_DCC`, `IS_HPC` | Environment detection flags |
| `CONDA_BASE` | Conda installation path (auto-detected) |
| `run-or-submit` | Submit SLURM on HPC, run locally otherwise |
| `run-array-or-submit` | Array job variant |
| `RUN_CMD` | Container + SLURM wrapper (DCC) |
| `RSCRIPT` | Convenience R wrapper |
| `PYTHON` | Convenience Python wrapper |
| `STATA` | Convenience Stata wrapper |
| `status` | Show recent SLURM jobs and output files |
| `logs` | Tail latest SLURM log |

Override defaults per-task: `PARTITION`, `TIME`, `MEM`, `CPUS`, `IMG`.

## Conda Environments

<!-- CUSTOMIZE: List your project's conda environments -->
Define environments in `environment.yml` or per-task YAML files:
```bash
conda env create -f environment.yml
conda activate <env_name>
```

## Container Support

<!-- CUSTOMIZE: Set your container image path -->
The Apptainer definition in `container/Apptainer.def` builds a
reproducible R environment. Deployed locations:
- **DCC:** `/opt/apps/containers/community/<user>/<project>.sif`
- **TACC:** `/work/<project_num>/<user>/<project>.sif`

Update process: edit `Apptainer.def`, rebuild, deploy to cluster.
See `container/README.md` for details.

## CI/CD — What Runs on PRs

| Workflow | Trigger | What it checks |
|----------|---------|---------------|
| `check_makefiles.yml` | PR open/reopen | All task Makefiles parse (`make -n`) |
| `check_nontask_makefiles.yml` | PR open/reopen | Paper/slides/logbook Makefiles parse |
| `check_code_quality.yml` | PR with task changes | Code quality rules (see below) |

## Code Quality Rules (Enforced on PR)

1. **No hardcoded user paths** — no `/Users/<x>/`, `/home/<x>/`, `/hpc/group/`
2. **No `setwd()`** — use relative paths or `optparse` arguments
3. **No multi-output rules without sentinel files** — prevents duplicate SLURM jobs
4. **Production scripts have Makefile targets** (warning)
5. **Reports should not do heavy computation** (warning, >50 lines of wrangling)

See `tasks/WORKFLOW.md` for the reports-vs-production policy.

## Commit Conventions

Short, one-line messages with conventional prefixes:
- `fix:` — bug fixes
- `feat:` — new features or tasks
- `refactor:` — restructuring (no behavior change)
- `report:` — Quarto/notebook-only changes
- `docs:` — documentation updates

## Agentic Workflow (Claude Code)

This project uses Claude Code with custom skills for research workflows:

1. **Plan before coding** — Use `Shift+Tab` (plan mode) for non-trivial tasks.
   Claude reads files but cannot execute until you approve.
2. **Independent review** — Use `/review-plan` to spawn a fresh agent that
   critiques the plan without conversational bias.
3. **Session continuity** — Use `/done` at end of session to capture decisions,
   open questions, and handoff notes for the next session.
4. **Structured prompts** — Use `/prompt` to convert stream-of-consciousness
   into Role/Context/Task/Constraints/Output/Bookend format.
5. **Code review** — Use `/review-code` for research-specific code checks
   (portability, reproducibility, HPC compatibility).

Principle: **Separate planning from reviewing.** Claude reviewing its own
plan in the same conversation has systematic self-bias. Always use a fresh
agent for review.

## Session Wrap-Up Template

<!-- CUSTOMIZE: Replace PROJECT_ALIAS with your project name -->
At end of session, generate a project manager update:
```
**PROJECT_ALIAS update**: <1-3 sentence summary>

**Next steps**:
1. <step>
2. <step>
```
