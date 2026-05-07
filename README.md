<div align="right">

[中文](#中文) | [English](#english)

</div>

# 中文

## Agency Codex Router Guard

`agency-codex-router-guard` 是这个项目现在更准确的名字。

它是一个面向 Codex 的 skill。它借鉴了 [`agency-agents`](https://github.com/msitarzewski/agency-agents) 的“专家路由”思路，但不只做 agent 选择，还会补上项目记忆、工作守则、切换边界和防打转升级机制。

它不是把几百个 agent 文件都塞进每个项目，而是做五件事：

1. 读取用户前 1 到 3 句话，加一次轻量仓库扫描
2. 为当前项目挑出一组足够小、足够合适的 specialist squad
3. 把结果写入 `.codex/project-profile.md`，方便后续在同一项目里复用
4. 在任务开始打转或改动失控前，触发 guardrails 和 escalation
5. 通过 curated catalog 和 presets，把 `agency-agents` 的核心 agent 真正纳入当前项目

现在已经不只覆盖通用 Web / API / 内容项目，也会把一部分上游专项 agent 真正接进自动路由：

- `ai-agent-stack`
- `game-production`
- `china-market-growth`
- `spatial-computing`

## 解决什么问题

- 新项目开局更快，不用每次都从零判断
- Codex 可以在同一轮会话里保持稳定的“专业视角”
- 不同仓库可以保留不同的默认 squad
- 当任务从开发切到设计、测试、产品、文案或策略时，可以自动切换 squad
- 当任务反复失败、验证不足或改动范围失控时，可以更早刹车，而不是越改越怪

## 仓库结构

```text
agency-codex-router-guard/
├── SKILL.md
├── agents/openai.yaml
├── references/agent-mapping.md
├── examples/project-profile.example.md
├── examples/project-profile.example.zh-CN.md
├── examples/new-project-dialogues.md
├── examples/new-project-dialogues.zh-CN.md
├── presets/
├── references/karpathy-operating-principles.md
├── references/distilled-agent-frameworks.md
├── references/high-agency-escalation.md
├── references/agency-agents-core-catalog.md
├── references/upstream-agent-divisions.md
├── upstream-agents/
├── scripts/install.sh
├── scripts/init-project.sh
├── scripts/update-profile.sh
└── scripts/scan-project.sh
```

## 安装

基础安装：

```bash
chmod +x scripts/install.sh scripts/init-project.sh
./scripts/install.sh
```

安装到 `~/.codex/skills`，并为某个项目自动生成中文 `.codex/project-profile.md`：

```bash
./scripts/install.sh --project /path/to/your/repo
```

如果是已部署或已有代码的项目，明确走扫描模式：

```bash
./scripts/install.sh --project /path/to/your/repo --mode scan
```

如果是新项目，明确走对话引导模式：

```bash
./scripts/install.sh --project /path/to/your/repo --mode dialog
```

如果你已经知道新项目方向，也可以直接把答案一起传进去，让 profile 自动生成更细的目标、约束和路由线索：

```bash
./scripts/install.sh \
  --project /path/to/your/repo \
  --mode dialog \
  --goal "web app" \
  --success "ready to ship" \
  --stack "nextjs" \
  --artifact "page" \
  --first-move "build ui"
```

如果你想生成英文模板：

```bash
./scripts/install.sh --project /path/to/your/repo --lang en
```

如果目标项目已经有 `project-profile.md`，想强制覆盖：

```bash
./scripts/install.sh --project /path/to/your/repo --force-profile
```

## 仅初始化项目 profile

如果你已经安装过 skill，只想给某个仓库初始化或重置 profile：

```bash
./scripts/init-project.sh --project /path/to/your/repo
./scripts/init-project.sh --project /path/to/your/repo --lang en
./scripts/init-project.sh --project /path/to/your/repo --mode scan
./scripts/init-project.sh --project /path/to/your/repo --mode dialog
./scripts/init-project.sh --project /path/to/your/repo --mode dialog --goal "api" --success "more reliable" --stack "python" --artifact "api" --first-move "build backend"
./scripts/init-project.sh --project /path/to/your/repo --force
```

也可以直接用扫描快捷脚本：

```bash
./scripts/scan-project.sh --project /path/to/your/repo
```

如果任务中途发生 reroute，希望保留当前 profile 但更新 squad，并自动追加一条带时间和原因的历史记录：

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --primary "Reality Checker" \
  --supporting "Frontend Developer,UX Architect,UI Designer" \
  --reason "任务从实现转向验收"
```

如果你已经知道要切到哪个 preset，现在也可以只传 `--preset`，让脚本自动补齐对应的 `Primary`、`Supporting`、`Upstream agents`、`Task Class`，并在未显式传 `Routing Cues` 参数时一起切到该 preset 的默认路由分支：

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --preset "ai-agent-stack" \
  --reason "仓库进入 agent 工程与评估闭环阶段"
```

如果你只想补一条新的 `Routing Cues` 分支，而不覆盖原有内容：

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --cue-mode append \
  --if-user-asks "无障碍、键盘导航、可访问性问题" \
  --switch-to "Accessibility Auditor" \
  --reason "补充无障碍路由分支"
```

如果你想用相近表述去归并已有分支，而不是新增一条重复分支：

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --cue-mode append \
  --cue-match semantic \
  --if-user-asks "响应式、上线验收、交付质量确认" \
  --switch-to "Reality Checker" \
  --reason "用近义表述归并验收分支"
```

如果任务阶段已经变化，也可以同步更新 `Task Class` 和 `Delivery Gate`：

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --task-class "lightweight" \
  --delivery-gate "关键交付目标已有人眼或浏览器验证" \
  --delivery-gate "未覆盖范围和风险已说明" \
  --delivery-gate "本轮不把体验猜测误报为完成" \
  --reason "任务进入最终验收阶段"
```

## 工作方式

在一个新仓库里，这个 skill 的理想流程是：

1. 先检查 `.codex/project-profile.md` 是否已经存在
2. 如果不存在，就根据你前几句描述和一次快速 repo 扫描判断项目类型
3. 选出 1 个主 specialist 和最多 3 个辅助 specialist
4. 把这个判断写入项目 profile
5. 在任务发生明显变化前，持续沿用这一组 squad

如果是新项目并且提供了对话答案，`dialog` 模式现在会直接把这些答案落成：

- `Current Goals`
- `Constraints`
- `Routing Cues`
- `Task Class`
- `Delivery Gate`
- `Squad History`

如果项目已经在推进中，`update-profile.sh` 现在可以在不重建整份 profile 的前提下：

- 更新 `Default Squad`
- 以 `replace`、`append`、`remove` 三种方式更新 `Routing Cues`
- 在 `append` / `remove` 时支持 `exact` 与 `semantic` 两种匹配方式
- 同步更新 `Task Class` 与 `Delivery Gate`
- 追加带时间和原因的 `Squad History`

## 项目 profile 示例

- 中文模板：[examples/project-profile.example.zh-CN.md](examples/project-profile.example.zh-CN.md)
- 英文模板：[examples/project-profile.example.md](examples/project-profile.example.md)
- 新项目对话模板（中文）：[examples/new-project-dialogues.zh-CN.md](examples/new-project-dialogues.zh-CN.md)
- New project dialogue template (English): [examples/new-project-dialogues.md](examples/new-project-dialogues.md)
- 核心 agent catalog：[references/agency-agents-core-catalog.md](references/agency-agents-core-catalog.md)
- Presets: [presets/README.md](presets/README.md)
- Upstream agent assets: [upstream-agents/README.md](upstream-agents/README.md)
- 来源整合审计：[references/source-integration-audit.md](references/source-integration-audit.md)

## 推荐使用方式

你可以直接在对话里点名：

```text
Use agency-codex-router-guard for this repo.
```

也可以让 Codex 在任务明显适合时自动使用。

## 当前已知可优化方向

- 自动扫描现在会读取少量关键配置与 README 标题，但规则仍然是启发式，不是深度理解
- 路由规则目前写在 `SKILL.md` 里，后续可以拆成更细的行业或任务模板
- `update-profile.sh` 现在已有第一版意图归并，但仍主要依赖规则与签名，不是完整自然语言理解

已经补上的优化：

- 已部署项目现在可以直接扫描并生成带 `Preset`、`Upstream agents`、`Handoff Triggers`、`Verification Protocol` 的 profile
- 不同项目类型已经会生成不同的决策规则、反模式、交接触发器和验证协议
- 安装脚本现在默认中文，并支持安装后立即为项目生成 profile
- 新项目对话答案现在可以直接落成 `Current Goals`、`Constraints`、`Routing Cues`
- `init-project.sh` 现在会按项目类型或新项目目标直接生成 `Task Class` 和 `Delivery Gate`
- 所有生成的 profile 现在都会带 `Squad History`
- `update-profile.sh` 现在可以在 reroute 时自动追加带时间和原因的历史记录
- `update-profile.sh` 现在也可以随着 reroute 同步更新 `Task Class` 和 `Delivery Gate`
- `update-profile.sh` 现在支持对 `Routing Cues` 做 `replace`、`append`、`remove`
- `update-profile.sh` 现在支持 `--cue-match semantic`，可用近义文案归并或删除分支
- `update-profile.sh` 现在会结合意图分组和目标角色做更稳的分支归并，降低误合并概率
- 扫描现有项目时，已经能自动识别并落到更深的专项 preset：AI / agent 工程、游戏开发、中国市场增长、空间计算
- 新项目对话模式现在也能直接生成这些专项 preset，而不是只落到通用 web / api / content 模板

下一步更值得继续做的增强：

- 为更多垂直行业继续补充 preset，例如电商、数据分析、金融工作流、销售流程
- 支持从真实对话文本里自动抽取这些字段，而不是只靠 CLI 传参
- 把当前规则型意图归并升级成更强的自然语言意图判断

## 吸收了哪些外部思路

- `forrestchang/andrej-karpathy-skills`
  - 吸收了更强调“小步、简洁、可验证”的执行纪律
- `alchaincyf`
  - 吸收了“蒸馏 skill / agent 时要提炼心智模型、决策规则、切换边界”的做法
  - 也单独吸收了女娲的“认知操作系统蒸馏”和达尔文的“评估-改进-回滚棘轮”方法
- `tanweai/pua`
  - 吸收了“代理开始打转时，需要有升级机制强制搜索、验证、换路径”的做法
  - 不默认合并其施压口吻，而是保留为可选升级层
- `msitarzewski/agency-agents`
  - 现在不只是借路由思路，也真正引入了 upstream agent 资产目录
  - 同时补了 curated core catalog 和 presets 层
- `OpenSpec + Superpowers + gstack`
  - 吸收了“需求层 / 执行层 / 验证层”分治方法，而不是把所有问题都混在一次对话里解决
  - 吸收了任务分级、交付门禁、Harness Engineering 棘轮这几套更适合生产环境的约束

## 说明

- 这个仓库面向 Codex skill 使用场景，不是完整的多 agent runtime
- 它刻意保持小而明确，方便修改和迁移
- 整体路由思路受到 `agency-agents` 启发，但实现是 Codex 原生化的

---

# English

## Agency Codex Router Guard

`agency-codex-router-guard` is the more accurate name for the project now.

It is a Codex skill that adapts the routing idea from [`agency-agents`](https://github.com/msitarzewski/agency-agents), but it now goes beyond routing into project memory, working rules, handoff boundaries, and anti-spinning escalation.

Instead of copying hundreds of role files into every workspace, this skill does five things:

1. reads the first 1-3 user messages plus a light repo scan
2. selects a small specialist squad for the current project
3. persists that choice in `.codex/project-profile.md` so future conversations in the same repo can resume faster
4. activates guardrails and escalation before repeated failures turn into messy damage
5. brings the core `agency-agents` roster into the project through a curated catalog and presets

It now routes beyond generic web/API/content work and can automatically choose deeper upstream specialist bundles for:

- `ai-agent-stack`
- `game-production`
- `china-market-growth`
- `spatial-computing`

## What it solves

- New project conversations start faster
- Codex can keep a stable specialist lens across the session
- Different repositories can keep different default squads
- The active squad can change when the task shifts from build to design, testing, product, content, or strategy
- The workflow can intervene earlier when work starts to spin or unsafe edits accumulate

## Repository layout

```text
agency-codex-router-guard/
├── SKILL.md
├── agents/openai.yaml
├── references/agent-mapping.md
├── examples/project-profile.example.md
├── examples/project-profile.example.zh-CN.md
├── examples/new-project-dialogues.md
├── examples/new-project-dialogues.zh-CN.md
├── presets/
├── references/karpathy-operating-principles.md
├── references/distilled-agent-frameworks.md
├── references/high-agency-escalation.md
├── references/agency-agents-core-catalog.md
├── references/upstream-agent-divisions.md
├── upstream-agents/
├── scripts/install.sh
├── scripts/init-project.sh
├── scripts/update-profile.sh
└── scripts/scan-project.sh
```

## Install

Basic install:

```bash
chmod +x scripts/install.sh scripts/init-project.sh
./scripts/install.sh
```

Install the skill and initialize a Chinese `.codex/project-profile.md` for a target repository:

```bash
./scripts/install.sh --project /path/to/your/repo
```

If the project already exists and you want to explicitly use scan mode:

```bash
./scripts/install.sh --project /path/to/your/repo --mode scan
```

If it is a new project and you want to explicitly use dialogue mode:

```bash
./scripts/install.sh --project /path/to/your/repo --mode dialog
```

If you already know the new-project direction, you can pass the dialogue answers directly and generate a richer profile immediately:

```bash
./scripts/install.sh \
  --project /path/to/your/repo \
  --mode dialog \
  --goal "web app" \
  --success "ready to ship" \
  --stack "nextjs" \
  --artifact "page" \
  --first-move "build ui"
```

Generate the English profile template instead:

```bash
./scripts/install.sh --project /path/to/your/repo --lang en
```

Overwrite an existing project profile:

```bash
./scripts/install.sh --project /path/to/your/repo --force-profile
```

## Initialize project profile only

If the skill is already installed and you only want to initialize or reset a project profile:

```bash
./scripts/init-project.sh --project /path/to/your/repo
./scripts/init-project.sh --project /path/to/your/repo --lang en
./scripts/init-project.sh --project /path/to/your/repo --mode scan
./scripts/init-project.sh --project /path/to/your/repo --mode dialog
./scripts/init-project.sh --project /path/to/your/repo --mode dialog --goal "api" --success "more reliable" --stack "python" --artifact "api" --first-move "build backend"
./scripts/init-project.sh --project /path/to/your/repo --force
```

You can also use the scan shortcut directly:

```bash
./scripts/scan-project.sh --project /path/to/your/repo
```

If the project is already in motion and you want to reroute without rebuilding the entire profile, you can update the active squad and append a timestamped history entry:

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --primary "Reality Checker" \
  --supporting "Frontend Developer,UX Architect,UI Designer" \
  --reason "Work shifted from implementation to verification"
```

If you already know which preset the project should move to, you can now pass only `--preset` and let the script auto-fill the matching `Primary`, `Supporting`, `Upstream agents`, `Task Class`, and default `Routing Cues` when those fields are omitted:

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --preset "ai-agent-stack" \
  --reason "The repo moved into agent engineering and evaluation work"
```

If you only want to add one more `Routing Cues` branch without replacing the existing ones:

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --cue-mode append \
  --if-user-asks "accessibility, keyboard navigation, contrast checks" \
  --switch-to "Accessibility Auditor" \
  --reason "Added accessibility verification branch"
```

If you want similar wording to merge into an existing branch instead of creating a duplicate:

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --cue-mode append \
  --cue-match semantic \
  --if-user-asks "QA handoff, release validation, readiness checks" \
  --switch-to "Reality Checker" \
  --reason "Merged verification cue using semantic match"
```

If the task has clearly moved into another phase, you can update `Task Class` and `Delivery Gate` at the same time:

```bash
./scripts/update-profile.sh \
  --project /path/to/your/repo \
  --task-class "lightweight" \
  --delivery-gate "The key deliverable has human or browser verification" \
  --delivery-gate "Remaining gaps and risks are stated explicitly" \
  --delivery-gate "This round does not report UX guesses as completion" \
  --reason "Work moved into final verification"
```

## How it works

On a new repo, the skill should:

1. check whether `.codex/project-profile.md` already exists
2. if not, infer project type from the first few user messages and a quick repo scan
3. choose one primary specialist and up to three supporting specialists
4. write the project profile for reuse
5. keep using that squad until the task meaningfully changes

When dialogue answers are provided for a new project, `dialog` mode now writes them directly into:

- `Current Goals`
- `Constraints`
- `Routing Cues`
- `Task Class`
- `Delivery Gate`
- `Squad History`

For ongoing projects, `update-profile.sh` can now:

- update `Default Squad`
- reroute by `--preset` and auto-fill the matching squad defaults
- reroute by `--preset` and replace `Routing Cues` with the preset's default cue branches unless explicit cue arguments are provided
- update `Routing Cues` via `replace`, `append`, or `remove`
- use either `exact` or `semantic` matching for `append` / `remove`
- update `Task Class` and `Delivery Gate`
- append timestamped `Squad History` entries with reroute reasons

## Example project profiles

- Chinese template: [examples/project-profile.example.zh-CN.md](examples/project-profile.example.zh-CN.md)
- English template: [examples/project-profile.example.md](examples/project-profile.example.md)
- Chinese new-project dialogue template: [examples/new-project-dialogues.zh-CN.md](examples/new-project-dialogues.zh-CN.md)
- English new-project dialogue template: [examples/new-project-dialogues.md](examples/new-project-dialogues.md)
- Core agent catalog: [references/agency-agents-core-catalog.md](references/agency-agents-core-catalog.md)
- Presets: [presets/README.md](presets/README.md)
- Upstream agent assets: [upstream-agents/README.md](upstream-agents/README.md)
- Source integration audit: [references/source-integration-audit.md](references/source-integration-audit.md)

## Recommended usage

You can explicitly mention the skill:

```text
Use agency-codex-router-guard for this repo.
```

Or let Codex apply it when the task clearly benefits from routing.

## Known optimization opportunities

- Scan-based routing now reads a few key config files and README headings, but it is still heuristic rather than deep repo understanding
- Routing rules are centralized in `SKILL.md`; they could later be split into domain-specific presets
- `update-profile.sh` now has a first-pass intent merge, but it still relies on rule-based signatures rather than full natural-language understanding

Already improved in this version:

- Existing repositories can now be scanned directly into a profile with `Preset`, `Upstream agents`, `Handoff Triggers`, and `Verification Protocol`
- Different project types now generate different heuristics, anti-patterns, handoff triggers, and verification rules
- The install script now defaults to Chinese and can install the skill while generating a project profile immediately
- New-project dialogue answers can now be written directly into `Current Goals`, `Constraints`, and `Routing Cues`
- `init-project.sh` now generates `Task Class` and `Delivery Gate` directly from project type or new-project intent
- All generated profiles now include `Squad History`
- `update-profile.sh` can now append timestamped reroute history entries automatically
- `update-profile.sh` can now update `Task Class` and `Delivery Gate` as the task phase changes
- `update-profile.sh` can now `replace`, `append`, or `remove` individual `Routing Cues` branches
- `update-profile.sh` can now use `--cue-match semantic` to merge or remove similar cue wording
- `update-profile.sh` now combines intent groups and target-role signatures to reduce accidental branch merges
- Existing-project scan can now auto-route into deeper presets for AI/agent engineering, game development, China-market growth, and spatial computing
- New-project dialogue mode can now generate those deeper presets directly instead of only falling back to generic web/API/content templates

Best next upgrades:

- Add more sector presets such as ecommerce, analytics, finance workflows, and sales operations
- Extract those dialogue fields directly from natural conversation, not only from CLI flags
- Upgrade the current rule-based intent merge into stronger natural-language intent understanding

## External ideas incorporated

- `forrestchang/andrej-karpathy-skills`
  - Inspired the small-step, simplicity-first, verifiable-execution discipline
- `alchaincyf`
  - Inspired the idea of distilling an agent into mental models, heuristics, and handoff boundaries instead of just tone
  - Also contributed Nuwa-style cognitive distillation and Darwin-style ratchet optimization ideas
- `tanweai/pua`
  - Inspired an optional anti-spinning escalation layer that forces verification, broader search, and alternative approaches
  - Its pressure tone is not enabled by default; only the operational escalation ideas are merged
- `msitarzewski/agency-agents`
  - Now included as actual upstream agent assets under `upstream-agents/`
  - Also represented through a curated core catalog plus preset layer
- `OpenSpec + Superpowers + gstack`
  - Contributed the separation between specification, execution, and verification layers
  - Also reinforced task sizing, delivery gates, and the Harness Engineering ratchet idea

## Notes

- This repo is designed for Codex skills, not as a full multi-agent runtime
- It is intentionally small and opinionated
- The routing concept was inspired by `agency-agents`, but the implementation here is Codex-native
