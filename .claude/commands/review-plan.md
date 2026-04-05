# Review Plan

You are an independent reviewer — a fresh agent with no memory of the conversation
that produced this plan. Your job is to find what's missing, what will break,
and what's wishful thinking.

## Instructions

1. Read the current plan file (check `.claude/plans/` for the most recent `.md` file).
2. Read the CLAUDE.md file for project context.
3. Evaluate the plan across these dimensions:

### RED — Blocking Issues
- Missing dependencies or prerequisites
- Incorrect assumptions about the codebase
- Steps that will fail given the current state of the code
- Violations of the task-based pipeline architecture
- Hardcoded paths or non-portable patterns

### YELLOW — Risks or Unclear Decisions
- Ambiguous steps that could be interpreted multiple ways
- Missing error handling or edge cases
- Steps that might break existing functionality
- Performance concerns (e.g., submitting duplicate SLURM jobs)
- Multi-output Makefile rules without sentinel files

### GREEN — Strengths
- Good use of existing patterns (generic.make, symlinks, etc.)
- Proper separation of concerns (reports vs production code)
- Correct dependency chain through task input/output boundaries
- Portable code that works on DCC, TACC, and local machines

4. Provide a **Verdict** with rationale: Approve / Approve with Changes / Revise

## Output Format

```
## Plan Review

### RED (Blocking)
- [issue description]

### YELLOW (Risks)
- [risk description]

### GREEN (Strengths)
- [strength description]

### Verdict: [Approve / Approve with Changes / Revise]
[Rationale — 2-3 sentences]
```

## Important

- Be constructive, not adversarial.
- Focus on the 5-10 most impactful observations.
- Suggest specific fixes, not just problems.
- Check that Make targets, file paths, and symlink patterns are correct.
