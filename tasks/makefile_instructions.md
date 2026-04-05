# How to Write a Task Makefile

## Standard Structure

Every task Makefile follows this template:

```makefile
# Task: <task_name>
# Purpose: <one-line description>

# 1. Define all final outputs
all: output/result.csv output/table.tex

# 2. Include shared infrastructure
include ../generic.make

# 3. Define upstream dependencies (symlinks)
input/upstream_data.csv: ../upstream_task/output/upstream_data.csv | input
	ln -sf $(abspath $<) $@

# 4. Define build rules
output/result.csv: code/process.R input/upstream_data.csv | output
	$(call RSCRIPT,code/process.R,--input $(abspath $<) --output $(abspath $@))

output/table.tex: code/make_table.R output/result.csv | output
	$(call RSCRIPT,code/make_table.R,--input $(abspath output/result.csv) --output $(abspath $@))
```

## Key Principles

1. **`all` target first** — list all final outputs as prerequisites.
2. **`include ../generic.make`** — get shared infrastructure.
3. **Symlinks use `$(abspath $<)`** — machine-specific absolute paths.
4. **Order-only prerequisites** — use `| input` and `| output` for directories.
5. **One recipe per output** — unless using sentinel file pattern.

## Symlink Conventions

```makefile
# Simple file symlink
input/data.csv: ../upstream_task/output/data.csv | input
	ln -sf $(abspath $<) $@

# Directory of files (e.g., shapefiles)
input/shapefiles: ../upstream_task/output/shapefiles | input
	rm -rf $@
	mkdir -p $@
	cd $< && find . -type f -print0 | \
	  xargs -0 -I{} ln -s "$(CURDIR)/$</{}" "$(CURDIR)/$@/{}"
```

## SLURM Patterns

### Pattern 1: Container execution (DCC)

```makefile
output/result.csv: code/script.R input/data.csv | output slurm_logs
	$(call RSCRIPT,code/script.R,--input $(abspath input/data.csv) --output $(abspath $@))
```

### Pattern 2: Submit or run locally

```makefile
output/result.csv: code/script.py input/data.csv | output
	@$(call run-or-submit,code/job.slurm,my_conda_env,python code/script.py)
```

### Pattern 3: Array jobs

```makefile
output/.arrays_done: code/script.py input/data.csv | output
	@$(call run-array-or-submit,code/job.slurm,0,9,my_env,python code/script.py)
	touch $@
```

### Pattern 4: Job dependency chaining

```makefile
output/final.csv: .jobids/step2 | output
	@echo "Waiting for step 2..."

.jobids/step2: .jobids/step1 code/step2.slurm | .jobids
	$(call submit-slurm-job,code/step2.slurm,.jobids/step1,.jobids/step2)

.jobids/step1: code/step1.slurm input/data.csv | .jobids
	$(call submit-slurm-job,code/step1.slurm,,.jobids/step1)
```

## Multi-Output Sentinel Pattern

```makefile
output/.regs_done: code/run_regressions.R input/panel.csv | output
	$(call RSCRIPT,code/run_regressions.R,--args ...)
	touch $@
output/table1.tex: output/.regs_done
output/table2.tex: output/.regs_done
output/figure1.pdf: output/.regs_done
```

## Resource Overrides

Set before `include ../generic.make`:

```makefile
TIME = 08:00:00
MEM  = 200G
CPUS = 8
PARTITION = scavenger
include ../generic.make
```

Or on the command line: `make MEM=300G TIME=12:00:00`

## Checklist for Adding a New Task

1. Create directory: `mkdir -p tasks/<task_name>/{code,input,output}`
2. Write `Makefile` following the template above.
3. Write `readme.md` documenting purpose, inputs, outputs.
4. Write production scripts in `code/` with command-line arguments.
5. Test locally: `make -n` (dry run), then `make`.
6. Verify symlinks: `ls -la input/` should show valid targets.
7. Run `make -C tasks/task_graph/code` to update the dependency graph.
8. Commit and create PR — CI will validate the Makefile.
