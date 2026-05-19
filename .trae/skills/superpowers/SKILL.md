---
name: superpowers
description: 专为 AI 编程设计的完整软件开发方法论框架，包含多个可组合的技能和工作流程（测试驱动开发、系统化调试、协作开发等）
---

# Superpowers

## 功能说明

Superpowers 是一个完整的 AI 编程软件开发方法论框架，通过一套可组合的 Skills 来规范 AI 开发行为，将软件开发提升到工程化水平。

**GitHub**: [obra/superpowers](https://github.com/obra/superpowers) | **Star**: ~100k

## 核心理念

- **测试驱动开发（TDD）** - 始终先写测试
- **系统化而非随机** - 流程优先于猜测
- **降低复杂性** - 简洁性作为主要目标
- **证据优于声明** - 在宣布成功之前先验证

## 基本工作流程

### 1. **brainstorming** - 构思阶段
- 在写代码之前激活
- 通过提问完善粗糙的想法
- 探索替代方案
- 分段展示设计供验证
- 保存设计文档

### 2. **using-git-worktrees** - 准备工作区
- 设计批准后激活
- 在新分支上创建隔离的工作空间
- 运行项目设置
- 验证干净的测试基线

### 3. **writing-plans** - 编写计划
- 设计批准后激活
- 将工作分解成小块任务（每个 2-5 分钟）
- 每个任务都有确切的文件路径、完整代码、验证步骤

### 4. **executing-plans** / **subagent-driven-development** - 执行计划
- 计划激活后启动
- 每个任务调度新的子代理进行两阶段审查（规范合规性，然后代码质量）
- 或批量执行并在人工检查点暂停

### 5. **test-driven-development** - 测试驱动开发
- 实现过程中激活
- 强制执行 RED-GREEN-REFACTOR 循环：
  1. 写失败的测试
  2. 看测试失败
  3. 写最少的代码
  4. 看测试通过
  5. 提交
- 删除测试前写的代码

### 6. **requesting-code-review** - 请求代码审查
- 任务之间激活
- 根据计划审查
- 按严重程度报告问题
- 严重问题阻止进度

### 7. **finishing-a-development-branch** - 完成开发分支
- 任务完成时激活
- 验证测试
- 提供选项（合并/PR/保留/丢弃）
- 清理工作树

## 技能库

### 测试
- **test-driven-development** - RED-GREEN-REFACTOR 循环

### 调试
- **systematic-debugging** - 4阶段根因分析过程
- **verification-before-completion** - 确保问题真正修复

### 协作
- **brainstorming** - 苏格拉底式设计完善
- **writing-plans** - 详细实施计划
- **executing-plans** - 带检查点的批量执行
- **dispatching-parallel-agents** - 并发子代理工作流
- **requesting-code-review** - 预审查清单
- **receiving-code-review** - 响应反馈
- **using-git-worktrees** - 并行开发分支
- **finishing-a-development-branch** - 合并/PR 决策工作流
- **subagent-driven-development** - 两阶段审查的快速迭代

### 元
- **writing-skills** - 遵循最佳实践创建新技能
- **using-superpowers** - 技能系统介绍

## 使用示例

> "帮我用 Superpowers 的方法开发一个新功能"
>
> "使用 TDD 模式来重构这个模块"
>
> "按照 Superpowers 的工作流程来规划这个项目"

## 安装来源

官方安装方式（Claude Code）：
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

或在 Claude Code 官方插件市场搜索 "superpowers"

## 适用场景

- 需要规范 AI 编程行为
- 想要工程化的软件开发流程
- 需要系统化的测试驱动开发
- 追求高质量代码和可维护性
