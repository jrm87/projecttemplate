# Prompt Structuring

Take the user's stream-of-consciousness input and restructure it into a
well-organized prompt using the six-section format.

## Instructions

1. Read the user's input (provided as $ARGUMENTS or the most recent message).
2. Identify the core intent, constraints, and desired output.
3. Restructure into the six sections below.
4. Present the structured prompt for the user to review and edit.

## Six-Section Format

```markdown
### Role
[Who should Claude be? e.g., "You are a research economist experienced
in spatial econometrics and Make-based build systems."]

### Context
[Background information Claude needs to do the job well. Include project
state, relevant files, prior decisions.]

### Task
[The specific thing to accomplish. Be concrete: "Write a Makefile for
task X that..." not "Help with the build system."]

### Constraints
[Hard rules and boundaries:
- Must use relative paths / optparse
- Must work on DCC and TACC
- Must follow sentinel file pattern for multi-output rules
- No hardcoded paths]

### Output Format
[What the deliverable should look like:
- "A Makefile with annotated comments"
- "An R script with optparse argument parsing"
- "A summary table comparing approaches"]

### Bookend
[How to verify success. e.g., "The task should pass `make -n` without
errors and follow the patterns in generic.make."]
```

## Guidelines

- Keep each section concise (2-5 lines).
- Constraints should include numbers, not adjectives ("< 50 lines" not "short").
- The Role should match the task's domain (econometrics, data engineering, etc.).
- Include file paths from the project when relevant.
- If the user's input is vague, ask clarifying questions before structuring.
