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
./scripts/init-project.sh --project /path/to/your/repo --force
```

也可以直接用扫描快捷脚本：

```bash
./scripts/scan-project.sh --project /path/to/your/repo
```

## 工作方式

在一个新仓库里，这个 skill 的理想流程是：

1. 先检查 `.codex/project-profile.md` 是否已经存在
2. 如果不存在，就根据你前几句描述和一次快速 repo 扫描判断项目类型
3. 选出 1 个主 specialist 和最多 3 个辅助 specialist
4. 把这个判断写入项目 profile
5. 在任务发生明显变化前，持续沿用这一组 squad

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
- 新项目对话已经模板化，但回答结果还没有自动映射成更细的约束字段
- 路由规则目前写在 `SKILL.md` 里，后续可以拆成更细的行业或任务模板
- 还没有“任务切换历史”，只能记住当前推荐 squad

已经补上的优化：

- 已部署项目现在可以直接扫描并生成带 `Preset`、`Upstream agents`、`Handoff Triggers`、`Verification Protocol` 的 profile
- 不同项目类型已经会生成不同的决策规则、反模式、交接触发器和验证协议
- 安装脚本现在默认中文，并支持安装后立即为项目生成 profile

下一步更值得继续做的增强：

- 把新项目对话答案自动落成 `Current Goals`、`Constraints`、`Routing Cues`
- 为不同行业继续补充 preset，例如电商、AI 工具、内容工作流、数据分析项目
- 增加 project-profile 的历史更新区，记录 squad 为什么切换

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
./scripts/init-project.sh --project /path/to/your/repo --force
```

You can also use the scan shortcut directly:

```bash
./scripts/scan-project.sh --project /path/to/your/repo
```

## How it works

On a new repo, the skill should:

1. check whether `.codex/project-profile.md` already exists
2. if not, infer project type from the first few user messages and a quick repo scan
3. choose one primary specialist and up to three supporting specialists
4. write the project profile for reuse
5. keep using that squad until the task meaningfully changes

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
- New-project dialogue mode exists, but the answers still do not auto-populate richer constraint fields
- Routing rules are centralized in `SKILL.md`; they could later be split into domain-specific presets
- There is no task-history memory yet, only the current recommended squad

Already improved in this version:

- Existing repositories can now be scanned directly into a profile with `Preset`, `Upstream agents`, `Handoff Triggers`, and `Verification Protocol`
- Different project types now generate different heuristics, anti-patterns, handoff triggers, and verification rules
- The install script now defaults to Chinese and can install the skill while generating a project profile immediately

Best next upgrades:

- Map new-project dialogue answers into `Current Goals`, `Constraints`, and `Routing Cues`
- Add more domain presets such as ecommerce, AI tools, content workflows, and analytics projects
- Add profile history so squad changes are recorded with reasons

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

## Notes

- This repo is designed for Codex skills, not as a full multi-agent runtime
- It is intentionally small and opinionated
- The routing concept was inspired by `agency-agents`, but the implementation here is Codex-native
