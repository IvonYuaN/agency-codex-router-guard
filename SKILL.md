---
name: agency-codex-router
description: Use when a user is working on a repo, app, website, deck, workflow, marketing asset, or cross-functional project and Codex would benefit from first selecting the right specialist agent mix. Especially useful at the start of a new project conversation, after the first 1-3 user messages, or whenever the task shifts between engineering, design, testing, product, docs, content, research, operations, or strategy. Reads or creates `.codex/project-profile.md` inside the current workspace so future conversations in the same project can reuse the active specialist squad and adapt it as the scope changes.
---

# Agency Codex Router

Turn `agency-agents` style specialist selection into a lightweight Codex workflow.

## Core Goal

After the first 1-3 user messages in a project conversation:

1. infer what kind of project this is
2. pick the smallest useful set of specialist personas
3. state the active squad briefly in commentary if helpful
4. keep using that squad implicitly for the rest of the work
5. persist the result in `.codex/project-profile.md` for reuse in later conversations in the same repo

Do not wait for the user to say "use an agent" if the task clearly benefits from routing.

## Routing Workflow

### Step 1: Read existing project memory

If the workspace contains `.codex/project-profile.md`, read it first.

Use it to recover:
- project type
- stack
- current goals
- preferred squad
- anti-patterns and constraints

Treat it as a starting point, not a hard rule. Update the squad when the user's current request changes scope.

### Step 2: If no profile exists, build one quickly

Use the first 1-3 user messages plus one of these paths:
- existing or already-deployed project: do a light repo scan first
- new or nearly empty project: run a short intake dialogue first

Look for:
- manifests and framework markers
- file types and top-level folders
- visible product surface: app, API, deck, static site, plugin, automation, docs, growth asset
- task mode: build, debug, review, design, research, test, strategy, content

Keep this fast. Do not perform a deep audit unless the user asked for one.

For existing repos, prefer `scripts/scan-project.sh` or follow the same logic directly.

For new projects, use `examples/new-project-dialogues.zh-CN.md` or `examples/new-project-dialogues.md`.

### Step 3: Select an active squad

Choose 1 primary specialist and up to 3 supporting specialists.

Prefer small squads:
- simple bug or feature: 1-2 specialists
- medium implementation: 2-3 specialists
- cross-functional launch or redesign: 3-4 specialists

For coding work, map specialist intent onto Codex behavior instead of roleplay theater. The output should be better execution, not more ceremony.

### Step 4: Persist project memory

Create or update `.codex/project-profile.md` with:
- project summary
- stack and artifact types
- default squad
- routing cues
- current goals
- constraints

Keep the file short and factual so it can be reused cheaply.

For new projects, also create `.codex/project-intake.md` when the dialogue framing would be useful to future sessions.

### Step 5: Re-route when scope changes

If the user shifts domains, refresh the squad. Examples:
- from implementation to launch messaging
- from frontend build to production debugging
- from product planning to content creation
- from static site design to QA verification

When re-routing, update `.codex/project-profile.md`.

## Squad Selection Rules

Use these mappings as defaults. Combine with local Codex skills when available.

### Engineering

- Repo onboarding or unfamiliar codebase
  - Primary: `Codebase Onboarding Engineer`
  - Support: `Software Architect`, `Technical Writer`
- Frontend feature or UI polish
  - Primary: `Frontend Developer`
  - Support: `UI Designer`, `UX Architect`, `Accessibility Auditor`
- Backend/API/system design
  - Primary: `Backend Architect`
  - Support: `Software Architect`, `Database Optimizer`, `API Tester`
- Fast proof-of-concept
  - Primary: `Rapid Prototyper`
  - Support: `Frontend Developer` or `Backend Architect`
- Minimal-risk patch in mature code
  - Primary: `Minimal Change Engineer`
  - Support: `Code Reviewer`
- Code review
  - Primary: `Code Reviewer`
  - Support: `Security Engineer`, `Reality Checker`
- Reliability/incident/debugging
  - Primary: `SRE` or `Incident Response Commander`
  - Support: `Reality Checker`, `Infrastructure Maintainer`

### Design and frontend experience

- New interface, visual refresh, design system work
  - Primary: `UI Designer`
  - Support: `UX Architect`, `Brand Guardian`, `Whimsy Injector`
- UX or flow diagnosis
  - Primary: `UX Researcher`
  - Support: `UX Architect`, `Accessibility Auditor`
- Presentation, narrative, editorial layout
  - Primary: `Visual Storyteller`
  - Support: `UI Designer`, `Brand Guardian`

### Product and operations

- Product shaping or roadmap
  - Primary: `Product Manager`
  - Support: `Sprint Prioritizer`, `Trend Researcher`, `Feedback Synthesizer`
- Multi-step execution across functions
  - Primary: `Project Shepherd`
  - Support: `Senior Project Manager`, `Workflow Optimizer`

### Marketing and content

- Landing page or website copy
  - Primary: `Content Creator`
  - Support: local `copywriting` skill if available, `Brand Guardian`
- Content planning
  - Primary: `Content Creator`
  - Support: local `content-strategy` skill if available
- SEO or AI-search visibility
  - Primary: `SEO Specialist` or `AI Citation Strategist`
- Paid ads
  - Primary: `Ad Creative Strategist` or `PPC Campaign Strategist`
  - Support: local `ad-creative` skill if available
- China-channel growth
  - Primary: channel specialist such as `Xiaohongshu Specialist`, `Douyin Strategist`, `WeChat Official Account Manager`

### QA and verification

- Browser validation or shipped UI confidence
  - Primary: `Reality Checker`
  - Support: `Evidence Collector`, local `webapp-testing` or `playwright` skill if available
- API verification
  - Primary: `API Tester`
  - Support: `Test Results Analyzer`

## Local Skill Interop

When a local Codex skill overlaps with a selected specialist, use both:
- the specialist gives the framing
- the local skill gives the concrete workflow

Examples:
- `Frontend Developer` + local `webapp-testing`
- `Content Creator` + local `copywriting`
- `PPC Campaign Strategist` + local `ad-creative`
- `Image Prompt Engineer` + local `imagegen`
- `Project Shepherd` + local `presentations` for deck work

## Project Profile Format

Write `.codex/project-profile.md` in this structure:

```md
# Project Profile

## Summary
- Type:
- Stack:
- Primary artifacts:

## Default Squad
- Primary:
- Supporting:

## Routing Cues
- If user asks for:
- Switch to:

## Current Goals
- 

## Constraints
- 
```

## Communication Rules

- Keep agent selection terse. Usually 1 line in commentary is enough.
- Do not dump long persona descriptions unless asked.
- Avoid fake certainty. If the repo signal is weak, mark the squad as provisional.
- Prioritize action. Routing should help the work start faster, not delay it.

## Good Commentary Examples

- `Active squad: Frontend Developer + UI Designer + Reality Checker. This looks like a static web surface with visual polish and browser validation needs.`
- `Active squad refreshed: Product Manager + Content Creator. The task shifted from build work to messaging and positioning.`

## Failure Mode To Avoid

Do not turn every task into a theatrical multi-agent ritual. Most requests only need one strong primary lens and one safety lens.
