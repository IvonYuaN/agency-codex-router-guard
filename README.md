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

Install the skill and initialize `.codex/project-profile.md` for a target repository:

```bash
./scripts/install.sh --project /path/to/your/repo
```

Overwrite an existing project profile:

```bash
./scripts/install.sh --project /path/to/your/repo --force-profile
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

---

# Agency Codex Router 中文说明

`agency-codex-router` 是一个面向 Codex 的 skill。它借鉴了 [`agency-agents`](https://github.com/msitarzewski/agency-agents) 的“专家路由”思路，但实现方式更轻量，也更适合 Codex 的实际工作流。

它不是把几百个 agent 文件都塞进每个项目，而是做三件事：

1. 读取用户前 1 到 3 句话，加一次轻量仓库扫描
2. 为当前项目挑出一组足够小、足够合适的 specialist squad
3. 把结果写入 `.codex/project-profile.md`，方便后续在同一项目里复用

## 解决什么问题

- 新项目开局更快，不用每次都从零判断
- Codex 可以在同一轮会话里保持稳定的“专业视角”
- 不同仓库可以保留不同的默认 squad
- 当任务从开发切到设计、测试、产品、文案或策略时，可以自动切换 squad

## 仓库结构

```text
agency-codex-router/
├── SKILL.md
├── agents/openai.yaml
├── references/agent-mapping.md
├── examples/project-profile.example.md
└── scripts/install.sh
```

## 安装

基础安装：

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

安装到 `~/.codex/skills`，并为某个项目自动生成 `.codex/project-profile.md`：

```bash
./scripts/install.sh --project /path/to/your/repo
```

如果目标项目已经有 `project-profile.md`，想强制覆盖：

```bash
./scripts/install.sh --project /path/to/your/repo --force-profile
```

手动安装：

```bash
mkdir -p ~/.codex/skills
cp -R agency-codex-router ~/.codex/skills/agency-codex-router
```

## 工作方式

在一个新仓库里，这个 skill 的理想流程是：

1. 先检查 `.codex/project-profile.md` 是否已经存在
2. 如果不存在，就根据你前几句描述和一次快速 repo 扫描判断项目类型
3. 选出 1 个主 specialist 和最多 3 个辅助 specialist
4. 把这个判断写入项目 profile
5. 在任务发生明显变化前，持续沿用这一组 squad

## 项目 profile 示例

见 [examples/project-profile.example.md](examples/project-profile.example.md)。

## 推荐使用方式

你可以直接在对话里点名：

```text
Use agency-codex-router for this repo.
```

也可以让 Codex 在任务明显适合时自动使用。

## 说明

- 这个仓库面向 Codex skill 使用场景，不是完整的多 agent runtime
- 它刻意保持小而明确，方便修改和迁移
- 整体路由思路受到 `agency-agents` 启发，但实现是 Codex 原生化的
