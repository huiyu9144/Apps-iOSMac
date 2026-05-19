---
name: baoyu-prompt
description: AI 提示词优化技能，将简单描述转换为高质量的 AI 绘画/生成提示词
---

# baoyu-prompt

## 功能说明

AI 提示词优化技能，属于 baoyu-skills 系列。将简单的描述转换为高质量的提示词，适用于 AI 绘画、图像生成等场景。

**GitHub**: [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills)
**作者**: 宝玉 (Baoyu)

## 功能特点

- 将简单的描述扩展为详细的提示词
- 支持多种 AI 绘画/生成场景
- 包含风格、细节、构图等专业要素
- 提升 AI 生成质量

## 使用场景

- 为 AI 图像生成准备提示词
- 优化和细化绘画描述
- 为 baoyu-imagine 提供输入
- 生成高质量 AI 绘画的 Prompt

## 使用方式

```bash
# 优化简单的提示词
/baoyu-prompt "一只橘猫"

# 从文件读取内容并优化
/baoyu-prompt path/to/draft.md

# 指定风格
/baoyu-prompt "海边日落" --style oil-painting
```

## 参数选项
| 参数 | 说明 |
|------|------|
| `--style <name>` | 指定绘画风格（如 oil-painting, anime, realistic 等） |
| `--detail <level>` | 详细程度（low, medium, high） |

## 安装来源

```bash
npx skills add jimliu/baoyu-skills
```

或通过 Claude Code 插件市场：
```
/plugin marketplace add JimLiu/baoyu-skills
/plugin install baoyu-skills@baoyu-skills
```
