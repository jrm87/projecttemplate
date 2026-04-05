#####################################################
# generic.make — Shared infrastructure for all tasks
#####################################################
# Include in every task Makefile:
#   include ../generic.make

# Ensure the including Makefile's `all` target is the default
.DEFAULT_GOAL := all

# ============================================================================
# Environment Detection
# ============================================================================
# Auto-detect whether we're on TACC, DCC, or a local machine.
# Override with: make IS_TACC=0  (force local) or make IS_TACC=1 (force TACC)
#
# Detection order:
#   1. TACC_SYSTEM env var (set automatically by TACC on all nodes)
#   2. SLURM_CLUSTER_NAME for DCC
#   3. sbatch in PATH (fallback for other SLURM clusters)
IS_TACC ?= $(shell [ -n "$$TACC_SYSTEM" ] && echo 1 || echo 0)
IS_DCC  ?= $(shell [ -n "$$SLURM_CLUSTER_NAME" ] && [ "$$SLURM_CLUSTER_NAME" = "dcc" ] && echo 1 || echo 0)
IS_HPC  ?= $(shell [ "$(IS_TACC)" = "1" ] || [ "$(IS_DCC)" = "1" ] && echo 1 || (command -v sbatch >/dev/null 2>&1 && echo 1 || echo 0))

# Repository root (for container bind mounts and slurm_helpers.sh)
REPO_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null || echo "..")

# ============================================================================
# Conda Path Resolution
# ============================================================================
# Conda lives in different places on TACC vs DCC vs local machines.
# Override with: make CONDA_BASE=/path/to/miniconda3
ifeq ($(IS_TACC),1)
  # CUSTOMIZE: Set your TACC project number and user mapping
  _USER_NAME := $(or $(shell echo $$USER),$(shell whoami))
  _PROJECT_NUM ?= 00000
  CONDA_BASE ?= /work/$(_PROJECT_NUM)/$(_USER_NAME)/ls6/miniconda3
else ifeq ($(IS_DCC),1)
  CONDA_BASE ?= $(HOME)/miniconda3
else
  # Common local paths — override if yours differs
  CONDA_BASE ?= $(or $(wildcard $(HOME)/miniconda3),$(wildcard /opt/homebrew/anaconda3),$(HOME)/miniconda3)
endif

# Default conda environment name (override per-task)
CONDA_ENV ?= base

# ============================================================================
# Container and SLURM Defaults (DCC-style)
# ============================================================================
# Override per-task by setting before `include ../generic.make`
# or on the command line: make MEM=200G TIME=08:00:00
# CUSTOMIZE: Set IMG to your project's container path
IMG         ?= /opt/apps/containers/community/YOUR_USER/YOUR_PROJECT.sif
PARTITION   ?= common
TIME        ?= 04:00:00
MEM         ?= 100G
CPUS        ?= 4
INTERACTIVE ?= 0

# ============================================================================
# Language Wrappers
# ============================================================================

# --- R via Container (DCC) or Conda (TACC) or Local ---
# Usage: $(call RSCRIPT,code/script.R,--arg1 val1 --arg2 val2)
ifeq ($(IS_DCC),1)
  # DCC: run inside Singularity container via SLURM
  define RSCRIPT
  $(call RUN_CMD,Rscript $(1) $(2))
  endef
else ifeq ($(IS_TACC),1)
  # TACC: run via conda + SLURM
  define RSCRIPT
  $(call run-or-submit,code/job.slurm,$(CONDA_ENV),Rscript $(1) $(2))
  endef
else
  # Local: run directly
  define RSCRIPT
  Rscript $(1) $(2)
  endef
endif

# --- Python via Conda ---
# Usage: $(call PYTHON,code/script.py,--arg1 val1)
define PYTHON
  source "$(CONDA_BASE)/etc/profile.d/conda.sh" && \
  conda activate $(CONDA_ENV) && \
  python $(1) $(2)
endef

# --- Stata ---
# Usage: $(call STATA,code/script.do)
STATA_CMD ?= $(shell command -v stata-mp 2>/dev/null || command -v stata 2>/dev/null || echo stata)
define STATA
  cd code && $(STATA_CMD) -b do $(notdir $(1))
endef

# ============================================================================
# Container + SLURM Wrappers (DCC-style)
# ============================================================================
# Low-level wrapper: runs any command inside container via SLURM
# $(call RUN_CMD,<full command string>)
define RUN_CMD
$(if $(filter 1,$(INTERACTIVE)),\
srun --partition=$(PARTITION) --time=$(TIME) --mem=$(MEM) \
  --cpus-per-task=$(CPUS) --pty \
  singularity exec --pwd "$$PWD" \
  --bind "$(REPO_ROOT):$(REPO_ROOT)" "$(IMG)" \
  $(1),\
sbatch --partition=$(PARTITION) --time=$(TIME) --mem=$(MEM) \
  --cpus-per-task=$(CPUS) \
  --job-name=$(notdir $(CURDIR)) \
  --output=slurm_logs/%j.out --error=slurm_logs/%j.err \
  --wrap='singularity exec --pwd "'"$$PWD"'" \
  --bind "$(REPO_ROOT):$(REPO_ROOT)" "$(IMG)" \
  $(1)')
endef

# ============================================================================
# SLURM Helpers (TACC-style: submit or run locally)
# ============================================================================
# Submit to SLURM on HPC, run directly on local machines.
# Args: $(1) = slurm script, $(2) = conda env name, $(3) = local command
define run-or-submit
  if [ "$(IS_HPC)" = "1" ]; then \
    echo "HPC detected — submitting to SLURM..."; \
    source $(REPO_ROOT)/tasks/slurm_helpers.sh; \
    submit_slurm_job '$(1)'; \
  else \
    echo "Local machine — running directly..."; \
    source "$(CONDA_BASE)/etc/profile.d/conda.sh" && \
    conda activate $(2) && \
    $(3); \
  fi
endef

# Submit array job to SLURM on HPC, run sequentially on local machines.
# Args: $(1) = slurm script, $(2) = array start, $(3) = array end,
#        $(4) = conda env name, $(5) = local command
define run-array-or-submit
  if [ "$(IS_HPC)" = "1" ]; then \
    echo "HPC detected — submitting array job to SLURM..."; \
    source $(REPO_ROOT)/tasks/slurm_helpers.sh; \
    submit_slurm_array_job '$(1)' '$(2)-$(3)'; \
  else \
    echo "Local machine — running array tasks $(2)..$(3) sequentially..."; \
    source "$(CONDA_BASE)/etc/profile.d/conda.sh" && \
    conda activate $(4) && \
    for i in $$(seq $(2) $(3)); do \
      echo "--- Array task $$i of $(3) ---"; \
      SLURM_ARRAY_TASK_ID=$$i $(5); \
    done; \
  fi
endef

# SLURM job submission with dependency chaining
# Usage: $(call submit-slurm-job,script,dependency_file,output_jobid_file)
define submit-slurm-job
	@DEPS=$$(cat $(2) 2>/dev/null || echo ""); \
	 JOB_ID=$$(bash -c "source $(REPO_ROOT)/tasks/slurm_helpers.sh; submit_slurm_job '$(1)' \"$$DEPS\""); \
	 if [ $$? -eq 0 ]; then \
	   echo $$JOB_ID > $(3); \
	   echo "Submitted job $$JOB_ID (depends on: $$DEPS)"; \
	 else \
	   echo "ERROR: Failed to submit job $(1)" >&2; \
	   exit 1; \
	 fi
endef

# Array job submission with dependency chaining
# Usage: $(call submit-slurm-array-job,script,array_spec,dependency_file,output_jobid_file)
define submit-slurm-array-job
	@DEPS=$$(cat $(3) 2>/dev/null || echo ""); \
	 JOB_ID=$$(bash -c "source $(REPO_ROOT)/tasks/slurm_helpers.sh; submit_slurm_array_job '$(1)' '$(2)' \"$$DEPS\""); \
	 if [ $$? -eq 0 ]; then \
	   echo $$JOB_ID > $(4); \
	   echo "Submitted array job $$JOB_ID [$(2)] (depends on: $$DEPS)"; \
	 else \
	   echo "ERROR: Failed to submit array job $(1)" >&2; \
	   exit 1; \
	 fi
endef

# ============================================================================
# Standard Directory Rules
# ============================================================================
input output temp report log slurm_logs:
	mkdir -p $@

.jobids:
	mkdir -p $@

# ============================================================================
# Upstream Dependency Resolution
# ============================================================================
# When a task Makefile references ../upstream_task/output/file, this rule
# auto-builds it by running make in the upstream task directory.
.PRECIOUS: ../%
../%: #Generic recipe to produce outputs from upstream tasks
	$(MAKE) -C $(subst output/,,$(dir $@)) output/$(notdir $@)

# ============================================================================
# Multi-Output Rules Warning
# ============================================================================
# GNU Make < 4.3 treats "a b: deps" as TWO separate rules with the SAME
# recipe, running it once per target (= duplicate SLURM jobs).
# Always use a sentinel file when a recipe produces multiple outputs:
#
#   output/.step_done: code/script.R input/data.csv
#       $(call RSCRIPT,code/script.R,--args ...)
#       touch $@
#   output/result_a.csv: output/.step_done
#   output/result_b.csv: output/.step_done
#
# See tasks/WORKFLOW.md for the full pattern.

# ============================================================================
# Status & Logging Targets
# ============================================================================
.PHONY: status logs clean

status:
	@echo "=== Recent SLURM jobs for $(notdir $(CURDIR)) ==="
	@sacct -u $$USER --name=$(notdir $(CURDIR)) \
	  --format=JobID%12,JobName%20,State%12,Elapsed,MaxRSS \
	  -S now-2days 2>/dev/null || \
	  echo "(sacct not available — not on SLURM cluster)"
	@echo ""
	@echo "=== Output files ==="
	@ls -lt output/ 2>/dev/null | head -10 || echo "No outputs yet"

logs:
	@latest=$$(ls -t slurm_logs/*.out 2>/dev/null | head -1); \
	if [ -n "$$latest" ]; then \
	  echo "=== $$latest ==="; \
	  tail -40 "$$latest"; \
	else \
	  echo "No SLURM logs yet in slurm_logs/"; \
	fi

clean:
	rm -rf output/ temp/
