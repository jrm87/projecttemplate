# Task: _example_task
# Purpose: Annotated skeleton showing all common Makefile patterns.
#          Copy this directory to create a new task:
#            cp -r tasks/_example_task tasks/my_new_task
#
# This file is a TEMPLATE — uncomment and adapt the patterns you need.

# ============================================================================
# 1. Define all final outputs
# ============================================================================
all: output/result.csv

# ============================================================================
# 2. Include shared infrastructure
# ============================================================================
# Override defaults BEFORE the include:
# TIME = 08:00:00
# MEM  = 200G
# CPUS = 8
# CONDA_ENV = my_env
include ../generic.make

# ============================================================================
# 3. Upstream dependencies (symlinks)
# ============================================================================
# Each input file is a symlink pointing to an upstream task's output.
# $(abspath $<) ensures the symlink uses a machine-specific absolute path.
# The "| input" is an order-only prerequisite — it just ensures the directory exists.

# input/upstream_data.csv: ../upstream_task/output/upstream_data.csv | input
# 	ln -sf $(abspath $<) $@

# ============================================================================
# 4. Build rules — LOCAL EXECUTION
# ============================================================================
# Simplest pattern: run a script directly (works on any machine).

output/result.csv: code/example.R | output
	Rscript code/example.R

# ============================================================================
# 5. Build rules — CONTAINER EXECUTION (DCC)
# ============================================================================
# Use RSCRIPT wrapper to run inside the Singularity container via SLURM.
# The wrapper handles sbatch (batch) or srun (interactive) based on INTERACTIVE flag.

# output/result.csv: code/example.R input/data.csv | output slurm_logs
# 	$(call RSCRIPT,code/example.R,--input $(abspath input/data.csv) --output $(abspath $@))

# ============================================================================
# 6. Build rules — SUBMIT OR RUN LOCALLY (TACC-style)
# ============================================================================
# run-or-submit: submits SLURM job on HPC, runs directly on local machines.
# Args: (slurm_script, conda_env_name, local_command)

# output/result.csv: code/example.py input/data.csv | output
# 	@$(call run-or-submit,code/example.slurm,my_conda_env,python code/example.py)

# ============================================================================
# 7. Array jobs
# ============================================================================
# run-array-or-submit: array job on HPC, sequential loop locally.
# Args: (slurm_script, start, end, conda_env, local_command)
# The local command can use $$SLURM_ARRAY_TASK_ID.

# output/.arrays_done: code/example.py input/data.csv | output
# 	@$(call run-array-or-submit,code/example.slurm,0,9,my_env,python code/example.py --task-id $$SLURM_ARRAY_TASK_ID)
# 	touch $@

# ============================================================================
# 8. Sentinel file pattern (multi-output rules)
# ============================================================================
# Use when one script produces multiple outputs.
# Without this, Make < 4.3 submits duplicate SLURM jobs.

# output/.regs_done: code/run_regressions.R input/panel.csv | output slurm_logs
# 	$(call RSCRIPT,code/run_regressions.R,--input $(abspath input/panel.csv))
# 	touch $@
# output/table1.tex: output/.regs_done
# output/table2.tex: output/.regs_done
# output/figure1.pdf: output/.regs_done

# ============================================================================
# 9. Job dependency chaining
# ============================================================================
# Submit jobs in sequence where each depends on the previous.

# .jobids/step2: .jobids/step1 code/step2.slurm | .jobids
# 	$(call submit-slurm-job,code/step2.slurm,.jobids/step1,.jobids/step2)
#
# .jobids/step1: code/step1.slurm input/data.csv | .jobids
# 	$(call submit-slurm-job,code/step1.slurm,,.jobids/step1)
