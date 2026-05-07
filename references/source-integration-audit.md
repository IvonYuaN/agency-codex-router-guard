# Source Integration Audit

Last reviewed: 2026-05-07

This file tracks what has actually been incorporated from the external sources discussed during development.

## 1. `msitarzewski/agency-agents`

### Already incorporated

- Vendored upstream markdown asset layer under `upstream-agents/`
- Curated working subset in `references/agency-agents-core-catalog.md`
- Reusable bundles in `presets/`
- Scan output now maps presets to concrete upstream agent file paths
- Scan and dialog routing now include deeper auto-selection for:
  - AI / agent engineering
  - game development
  - China-market growth workflows
  - spatial computing

### Not yet incorporated

- Upstream shell scripts and non-markdown tool integrations are not part of Router Guard's runtime
- Upstream installation workflows for Claude Code, Cursor, Copilot, Aider, etc. are not mirrored as first-class Router Guard features
- Upstream coordination playbooks are vendored as files, but not yet wired into Router Guard's scan or preset logic
- Many specialized sectors still remain asset-only and are not yet part of automatic routing

## 2. `forrestchang/andrej-karpathy-skills`

### Already incorporated

- Think before coding
- Simplicity first
- Surgical changes
- Goal-driven / verifiable execution
- These ideas are reflected in:
  - `references/karpathy-operating-principles.md`
  - `SKILL.md`
  - generated `Working Style`

### Not yet incorporated

- The original `.claude-plugin` packaging is not mirrored
- Cursor-specific rule packaging is not mirrored
- The single-file install pattern (`CLAUDE.md`, `CURSOR.md`) is not reproduced as standalone Router Guard exports

## 3. `tanweai/pua`

### Already incorporated

- High-agency escalation as an optional layer
- Trigger idea: repeated failure, spinning, excuse-making, skipped verification
- Escalation idea: require new approach, evidence, and broader search

### Not yet incorporated

- Full original PUA prompt/persona package is not vendored
- Full trigger matrix and style variations are not mirrored
- Aggressive tone is intentionally not defaulted into Router Guard

## 4. `alchaincyf`

### Already incorporated

- The idea of distilling an agent into:
  - mental model
  - decision heuristics
  - handoff boundaries
- Reflected in:
  - `references/distilled-agent-frameworks.md`
  - `Working Style`
  - `Handoff Triggers`
- Nuwa-specific method layer now reflected in:
  - `references/nuwa-distillation-principles.md`
- Darwin-specific optimization layer now reflected in:
  - `references/darwin-optimization-principles.md`

### Not yet incorporated

- No specific `alchaincyf` repository has been vendored
- No concrete upstream files from that GitHub account are currently part of this repo
- Only the method layer has been absorbed so far, not the original repo assets

## Honest current state

Router Guard now contains:

- real upstream `agency-agents` markdown assets
- a real curated catalog
- real presets
- real scan-to-upstream-file mapping
- real deep-sector auto-routing for a selected subset of upstream domains

But it does not yet contain:

- full executable parity with the upstream tool ecosystems
- deep specialized-sector routing across all 180+ upstream agents
- concrete vendored assets from `alchaincyf`
- full packaged exports of the Karpathy or PUA systems

## Highest-value remaining gaps

1. Add more sector presets beyond the first four deeper integrations
2. Wire upstream coordination playbooks into Router Guard's reroute or escalation logic
3. Decide whether a specific `alchaincyf` repository should be vendored instead of only borrowing abstract ideas
4. Add a source-sync policy so future upstream pulls stay auditable
