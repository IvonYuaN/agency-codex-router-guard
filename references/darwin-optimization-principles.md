# Darwin Optimization Principles

Distilled from `alchaincyf/darwin-skill`.

## What Darwin adds

Darwin treats a skill like an optimizable asset:

- evaluate
- improve
- test
- keep or revert

## Core mechanisms worth borrowing

- single editable asset per iteration
- dual evaluation: structure + real output
- ratchet: keep improvements, revert regressions
- independent scoring where possible
- human-in-the-loop pause between larger rounds

## Router Guard implications

When Router Guard evolves:

- treat `SKILL.md` and presets as assets that can be improved
- prefer measurable improvement over stylistic churn
- keep a working baseline
- revert regressions cleanly
- do not let "more changes" masquerade as "better skill"
