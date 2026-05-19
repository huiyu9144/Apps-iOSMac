---
name: baoyu-markdown-to-html
description: Markdown 转 HTML 工具技能，将 Markdown 格式内容转换为美观的 HTML 页面
---

# baoyu-markdown-to-html

## 功能说明

Markdown 转 HTML 工具技能，属于 baoyu-skills 系列。将 Markdown 格式内容转换为美观、样式规范的 HTML 页面，适合发布到网页或邮件。

**GitHub**: [JimLiu/baoyu-skills](https://github.com/JimLiu/baoyu-skills)
**作者**: 宝玉 (Baoyu)

## 功能特点

- 将 Markdown 转换为语义化 HTML
- 支持代码高亮、表格、列表等元素
- 生成自包含的 HTML 文件
- 支持自定义样式

## 使用场景

- 将文章从 Markdown 转换为网页
- 生成 HTML 格式的邮件内容
- 创建博客文章的 HTML 版本
- 发布内容到需要 HTML 格式的平台

## 使用方式

```bash
# 将 Markdown 文件转为 HTML
/baoyu-markdown-to-html path/to/article.md

# 指定输出路径
/baoyu-markdown-to-html path/to/article.md --out docs/index.html

# 指定样式主题
/baoyu-markdown-to-html path/to/article.md --theme dark
```

## 参数选项
| 参数 | 说明 |
|------|------|
| `--out <path>` | 输出文件路径 |
| `--theme <name>` | 样式主题（light, dark, github 等） |
| `--lang <code>` | 输出语言（en, zh 等） |

## 示例

```markdown
输入：
# Hello World
这是一个 **Markdown** 转 HTML 的示例。

- 项目 1
- 项目 2

输出：
<h1>Hello World</h1>
<p>这是一个 <strong>Markdown</strong> 转 HTML 的示例。</p>
<ul>
  <li>项目 1</li>
  <li>项目 2</li>
</ul>
```

## 安装来源

```bash
npx skills add jimliu/baoyu-skills
```

或通过 Claude Code 插件市场：
```
/plugin marketplace add JimLiu/baoyu-skills
/plugin install baoyu-skills@baoyu-skills
```
