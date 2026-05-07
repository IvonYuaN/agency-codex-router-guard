# OpenSpec + Superpowers + gstack Distillation

Distilled from: `OpenSpec_Superpowers_gstack_AI增强开发工作流实战.md`

This reference matters because it does not just recommend more tools. It proposes a stable split between:

- specification alignment
- execution discipline
- verification and delivery

That split maps well onto `agency-codex-router-guard`.

## Core Model

Treat AI project work as three layers:

1. Specification layer
   - clarify what is being changed
   - define success criteria
   - define boundaries and risks
2. Execution layer
   - break work into bounded tasks
   - isolate execution context
   - force explicit review and verification loops
3. Verification layer
   - validate user-visible output
   - validate end-to-end behavior
   - validate delivery readiness

In router-guard terms:

- project profile and routing cues cover the specification memory layer
- presets, squad routing, and guardrails cover the execution layer
- verification protocol, reality-check routing, and reroute history cover the verification layer

## High-Value Ideas To Keep

### 1. Task sizing before workflow depth

Do not send every task through the same ceremony.

- lightweight task
  - small scoped fix
  - single-file or bounded multi-file change
  - clear expected result
- medium task
  - feature work with clear boundaries
  - several files or one subsystem
  - needs explicit plan and stronger verification
- large task
  - cross-module change
  - shared contracts or architecture movement
  - needs explicit spec alignment, staged execution, and delivery gate

This should change:

- how much routing ceremony is used
- how many specialists are activated
- how much verification evidence is required

### 2. Specification before implementation

When a repo already has an `openspec/` style workflow or other explicit change-doc workflow:

- prefer updating the change proposal before large implementation
- use proposal/design/tasks as routing input
- treat code as downstream of explicit intent, not the primary source of intent

### 3. Delivery gate

Completion claims should be blocked unless there is evidence.

Minimum delivery gate:

- relevant implementation done
- relevant verification done
- limits or missing checks stated explicitly
- no fabricated success claims

### 4. Harness Engineering ratchet

The strongest idea in the document is the ratchet:

> each repeated agent failure should become a new workflow constraint

In router-guard form:

- repeated failure updates anti-patterns
- reroute history records why the workflow changed
- future presets and routing heuristics should absorb these failures

## What Not To Copy Blindly

- Tool-specific command names
- Claude-only assumptions
- rigid seven-step ceremony for every task

Router-guard should absorb the operating principles, not cargo-cult the exact tool wrappers.

## Recommended Router-Guard Translation

1. Add task sizing guidance to routing.
2. Add spec-first guidance for medium/large changes when explicit spec docs exist.
3. Keep a delivery gate as a completion rule.
4. Keep turning repeated failures into reusable guardrails.
