# Session Wrap-Up

End-of-session wrap-up. Capture what was accomplished, what's pending,
and prepare a handoff for the next session.

## Instructions

1. Review the conversation history for this session.
2. Identify:
   - What was accomplished (files created, modified, bugs fixed, etc.)
   - Decisions made and their rationale
   - Open questions or unresolved issues
   - Next steps (prioritized)
3. Write a handoff note to `.claude/handoff.md` with the format below.
4. Generate a project manager update for the user.

## Handoff Note Format (write to .claude/handoff.md)

```markdown
# Session Handoff — [DATE]

## What Was Done
- [Concrete accomplishments with file paths]

## Decisions Made
- [Decision]: [Rationale]

## Open Questions
- [Question that needs resolution]

## Next Steps (Priority Order)
1. [Most important next action]
2. [Second priority]
3. [Third priority]

## Working State
- Branch: [current branch]
- Uncommitted changes: [yes/no, summary if yes]
- Tests passing: [yes/no/not run]
```

## Project Manager Update

Also output to the user:

```
**PROJECT update**: [1-3 sentence summary of what was done]

**Next steps**:
1. [step]
2. [step]
```

Replace PROJECT with the actual project name from CLAUDE.md.
