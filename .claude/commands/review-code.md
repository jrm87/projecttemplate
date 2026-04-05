# Research Code Review

Review code changes for research-specific quality concerns. This goes beyond
syntax — it checks for reproducibility, portability, and pipeline integrity.

## Instructions

1. Identify the files changed in the current branch (or the files the user specifies).
2. For each changed file, evaluate against the checklist below.
3. Report findings using the Red/Yellow/Green format.

## Checklist

### Reproducibility
- [ ] Random seeds set where randomness is used
- [ ] Package versions pinned or documented
- [ ] No interactive input required (can run via `Rscript` / `python` non-interactively)
- [ ] Results deterministic given same inputs

### Portability (Local + DCC + TACC)
- [ ] No hardcoded absolute paths (`/Users/...`, `/home/...`, `/hpc/...`, `/work/...`)
- [ ] No `setwd()` in R; no `os.chdir()` in Python
- [ ] File paths passed via command-line args (optparse/argparse) or relative paths
- [ ] Works inside Singularity container (no host-specific dependencies)
- [ ] Symlinks use `$(abspath $<)` in Makefiles

### Pipeline Integrity
- [ ] Script has a corresponding Makefile target
- [ ] Reads from `input/`, writes to `output/` (not cross-task paths)
- [ ] Multi-output rules use sentinel file pattern
- [ ] No side effects outside `output/` and `temp/`

### Code Quality
- [ ] No magic numbers — use named constants or command-line args
- [ ] Error handling for file I/O (missing input files, write failures)
- [ ] Reasonable memory usage (no loading 100GB into RAM unnecessarily)
- [ ] SLURM resource requests match actual needs (TIME, MEM, CPUS)

### Documentation
- [ ] Task has a `readme.md` explaining purpose, inputs, outputs
- [ ] Complex logic has inline comments
- [ ] Commit message follows conventions (fix:/feat:/refactor:/report:/docs:)

## Output Format

```
## Code Review: [file or task name]

### RED (Must Fix)
- [issue with file path and line number]

### YELLOW (Should Fix)
- [concern with suggestion]

### GREEN (Good Practices)
- [things done well]

### Summary
[1-2 sentence overall assessment]
```

## Important

- Focus on the 5-10 most impactful findings.
- Suggest specific fixes with code snippets when possible.
- Check that the code actually works with `generic.make` patterns.
- Verify Makefile symlink patterns match actual upstream task names.
