# Project Profile

## Summary
- Type: 演示型静态网页产物
- Stack: 单页 HTML，配合本地 assets 与 images
- Primary artifacts: `index.html`、图片资源、演示视觉稿

## Default Squad
- Preset: `ppt-storytelling`
- Primary: `Visual Storyteller`
- Supporting: `UI Designer`、`Frontend Developer`、`Reality Checker`
- Upstream agents:
  - `upstream-agents/design/design-visual-storyteller.md`
  - `upstream-agents/design/design-ui-designer.md`
  - `upstream-agents/engineering/engineering-frontend-developer.md`
  - `upstream-agents/testing/testing-reality-checker.md`

## Routing Cues
- If user asks for: 布局、视觉层级、叙事结构、品牌表达
- Switch to: `Visual Storyteller` + `UI Designer`
- If user asks for: 标记结构、样式、交互实现
- Switch to: `Frontend Developer`
- If user asks for: 验证、响应式检查、可交付性确认
- Switch to: `Reality Checker`

## Current Goals
- 维护演示型网页产物的视觉表达质量
- 在仓库结构未明显演进前，优先保持单页静态交付方式

## Constraints
- 除非明确要求重构，否则优先做最小结构改动
- 保持与本地静态资源工作流兼容

## Working Style
- 先做小步可验证改动，再决定是否扩大范围

## Decision Heuristics
- 优先保留主导视角的认知模型，而不是只模仿表达口吻
- 优先做最小有效改动，再决定是否扩大范围

## Anti-Patterns
- 不要只切换说话风格，却没有切换思考方式
- 不要在没有证据时持续扩大改动面

## Handoff Triggers
- 当任务从叙事设计进入页面实现时，切换到 `Frontend Developer`
- 当任务从实现进入验收和上线判断时，切换到 `Reality Checker`

## Escalation Policy
- 当同一路径连续失败 2 次以上时，切换到高能动排查模式
- 声称完成前必须有可验证证据

## Verification Protocol
- 优先验证最关键的用户路径或核心输出
- 检查相邻影响面，而不是只看改动点本身
- 区分“演示可用”与“生产可用”

## Evolution Loop
- 保留有效改动
- 回滚回归和劣化
- 每次迭代都要比上一个稳定版本更可信
