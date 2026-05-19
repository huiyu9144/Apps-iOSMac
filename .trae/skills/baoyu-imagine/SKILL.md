---
name: baoyu-imagine
description: AI 图像生成技能，优化后的图像生成方案，支持多种 AI 后端
---

# baoyu-imagine

## 功能说明

AI 图像生成技能，属于 baoyu-skills 系列。优化后的图像生成方案，支持多种 AI 后端，帮助用户高效生成高质量的 AI 图片。

**GitHub**: [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills)
**作者**: 宝玉 (Baoyu)

## 功能特点

- 支持多种 AI 图像生成后端
- 优化后的图像生成流程
- 高质量图像输出
- 灵活的配置选项

## 使用场景

- 生成文章配图
- 创建社交媒体图片
- 制作产品展示图
- 生成创意素材

## 使用方式

### 基本使用
```bash
# 从内容生成图片
/baoyu-imagine "一只可爱的橘猫在阳光下打盹"

# 从文件生成图片
/baoyu-imagine path/to/prompt.md
```

### 参数选项
| 参数 | 说明 |
|------|------|
| `--style <name>` | 指定图像风格 |
| `--ratio <ratio>` | 指定宽高比（16:9, 9:16, 1:1 等） |
| `--count <number>` | 生成图片数量 |

## 安装来源

```bash
npx skills add jimliu/baoyu-skills
```

或通过 Claude Code 插件市场：
```
/plugin marketplace add JimLiu/baoyu-skills
/plugin install baoyu-skills@baoyu-skills
```
