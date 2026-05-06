# Upstream Agents

This directory vendors the upstream markdown agent assets from:

- `msitarzewski/agency-agents`

## Structure

This repo now has two layers:

1. `upstream-agents/`
   - the original industry and role agent files
2. `references/`, `presets/`, and `scripts/`
   - the Router Guard layer that selects, persists, and governs usage

## Why both layers exist

- `upstream-agents/` gives you the actual upstream assets
- `references/agency-agents-core-catalog.md` gives you a curated working subset
- `presets/` gives you reusable routing bundles for common project types
