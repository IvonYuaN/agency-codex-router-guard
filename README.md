# Agency Codex Router

`agency-codex-router` is a Codex skill that adapts the routing idea from [`agency-agents`](https://github.com/msitarzewski/agency-agents) into a lightweight, practical workflow for Codex.

Instead of copying hundreds of role files into every workspace, this skill does three things:

1. reads the first 1-3 user messages plus a light repo scan
2. selects a small specialist squad for the current project
3. persists that choice in `.codex/project-profile.md` so future conversations in the same repo can resume faster

## What it solves

- New project conversations start faster
- Codex can keep a stable specialist lens across the session
- Different repositories can keep different default squads
- The active squad can change when the task shifts from build to design, testing, product, content, or strategy

## Repository layout

```text
agency-codex-router/
├── SKILL.md
├── agents/openai.yaml
├── references/agent-mapping.md
├── examples/project-profile.example.md
└── scripts/install.sh
```

## Install

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

Manual install:

```bash
mkdir -p ~/.codex/skills
cp -R agency-codex-router ~/.codex/skills/agency-codex-router
```

## How it works

On a new repo, the skill should:

1. check whether `.codex/project-profile.md` already exists
2. if not, infer project type from your first few messages and a quick repo scan
3. choose one primary specialist and up to three supporting specialists
4. write the project profile for reuse
5. keep using that squad until the task meaningfully changes

## Example project profile

See [examples/project-profile.example.md](examples/project-profile.example.md).

## Recommended usage

You can explicitly mention the skill:

```text
Use agency-codex-router for this repo.
```

Or let Codex apply it when the task clearly benefits from routing.

## Notes

- This repo is designed for Codex skills, not as a full multi-agent runtime.
- It is intentionally small and opinionated.
- The routing concept was inspired by `agency-agents`, but the implementation here is Codex-native.
