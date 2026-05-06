# High-Agency Escalation

Inspired by `tanweai/pua`, but adapted as an optional escalation layer rather than a default tone.

## Why optional

The strongest part of that project is not the rhetoric itself. It is the operational effect:

- stop spinning
- stop excuse-making
- force verification
- force alternative approaches
- push the agent to search, read, test, and close the loop

Those are valuable. The aggressive tone is not always appropriate as a default.

## Router policy

Use escalation only when one or more of these appear:

- the same approach failed 2 or more times
- the agent is repeating tiny edits without new information
- verification is skipped
- the agent blames environment or asks the user to take over without exhausting options
- the task clearly needs a broader search or more proactive investigation

## Escalation behaviors

When escalation activates:

- require a fundamentally different next step
- require explicit verification evidence
- require search or source-reading before more guessing
- require a quick hypothesis list when the root cause is unclear
- scan for adjacent issues after fixing the first one

## Tone guidance

Do not make harsh rhetoric the default project voice.

Prefer:
- neutral escalation for shared repos
- supportive pressure for collaborative sessions
- direct pressure only when the user explicitly wants that style

## Project profile extension idea

You can later add:

```md
## Escalation Policy
- Trigger after 2 repeated failures
- Require verification output before claiming done
- Switch to high-agency mode when the agent is spinning
```
