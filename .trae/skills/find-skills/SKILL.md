---
name: find-skills
description: 帮助用户查找和发现适合的技能，根据用户需求推荐合适的技能
---

# Find Skills

## 功能说明

本技能帮助用户查找、发现和推荐适合的技能，解决"不知道该用什么 skill"的痛点。

## 使用场景

当用户：
- 需要完成特定任务但不知道用哪个 skill
- 想要优化开发工作流
- 查找相关领域的专业技能
- 需要技能推荐

## 查找技能的步骤

1. 首先了解当前项目中已有的技能：
   - 扫描 `.trae/skills/` 目录
   - 列出所有已安装的技能及其描述

2. 与用户对话，了解他们的具体需求，例如：
   - "需要优化前端代码"
   - "iOS/macOS 开发相关"
   - "文档处理"
   - "测试相关"
   - 等

3. 根据需求分析推荐合适的技能：
   - 如果本地已安装，推荐最合适的
   - 如果没有，推荐常用的官方技能（来自 anthropics/skills 仓库）

4. 提供示例用法帮助用户理解如何使用该技能

## 已有的常用技能分类

### 文档处理
- pdf - PDF 文档处理
- docx - Word 文档处理
- xlsx - Excel 电子表格处理
- pptx - PowerPoint 演示文稿处理

### 前端开发
- frontend-design - 高品质前端界面设计
- web-artisan - 全栈 Web 应用开发
- canvas-design - Canvas 设计

### 技术开发
- mcp-server-generation - MCP 服务器生成
- testing-web-apps - Web 应用测试
- test-driven-development - 测试驱动开发

### 其他
- doc-coauthoring - 文档协同
- skill-creator - 创建新技能

## 示例

> "帮我找到优化前端的 skill"

> "iOS 开发相关的 skill 有哪些"

## 指南

- 先了解本地已有的技能
- 根据用户需求的精确描述来推荐
- 提供清晰的示例帮助用户理解如何使用
