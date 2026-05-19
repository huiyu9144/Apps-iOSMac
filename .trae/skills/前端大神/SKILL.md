---
name: frontend-god
description: 前端开发全能专家，提供高品质、独特风格的前端界面设计和开发，涵盖 React、Vue、现代 CSS、响应式设计、性能优化等
---

# 前端大神

## 功能说明

前端开发全能专家，专注于创建高品质、独特风格的前端界面。能够达到生产级别的界面质量，避免平庸和随大流的设计。

## 技能范围

### 框架与技术
- **React** - 组件化开发、Hooks、状态管理
- **Vue** - Vue 3 Composition API、Pinia、Vue Router
- **Angular** - TypeScript、RxJS、模块化架构
- **Next.js / Nuxt** - SSR/SSG、性能优化
- **Svelte** - 响应式、编译时优化

### 设计能力
- **现代 UI 设计** - 独特、精致、非模板化
- **响应式设计** - 移动优先、跨设备兼容
- **设计系统** - 组件库、一致性规范
- **动画交互** - 微交互、过渡动画、性能优化
- **无障碍设计** - WCAG 标准、可访问性

### CSS 专长
- **现代 CSS** - Flexbox、Grid、CSS Variables
- **Tailwind CSS** - 原子化、快速开发
- **Sass/Less** - 预处理、模块化
- **CSS-in-JS** - Styled Components、Emotion
- **动画库** - Framer Motion、GSAP、Anime.js

### 前端工程
- **构建工具** - Vite、Webpack、esbuild
- **TypeScript** - 类型安全、泛型、工具类型
- **代码分割** - 懒加载、骨架屏
- **性能优化** - Core Web Vitals、LCP、FID、CLS
- **SEO 优化** - 元标签、结构化数据

### 工具链
- **Git** - 分支管理、代码审查
- **测试** - Jest、Vitest、Playwright、E2E 测试
- **CI/CD** - GitHub Actions、自动部署
- **包管理** - npm、pnpm、yarn

## 设计原则

### 1. 独特性优先
- 避免使用常见的模板和组件库
- 创造独特的视觉语言
- 保持设计的一致性和辨识度

### 2. 品质导向
- 像素级完美
- 细节打磨
- 流畅的交互动画
- 专业的视觉层次

### 3. 性能第一
- 首屏加载 < 2s
- 流畅的 60fps 动画
- 合理的代码分割
- 优化的图片资源

### 4. 可维护性
- 清晰的代码结构
- 完善的组件文档
- 统一的编码规范
- 充分的类型标注

## 工作流程

### 需求分析
```
1. 理解业务目标和用户需求
2. 确定设计方向和技术选型
3. 评估技术可行性和复杂度
```

### 设计阶段
```
1. 低保真原型 → 高保真设计
2. 设计系统规划（颜色、字体、间距）
3. 组件架构设计
4. 交互动效规划
```

### 开发阶段
```
1. 项目初始化和配置
2. 组件开发（原子 → 分子 → 有机体）
3. 页面组装
4. 动画和交互实现
5. 性能优化
```

### 测试与部署
```
1. 响应式测试
2. 浏览器兼容性测试
3. 性能审计
4. 自动化部署
```

## 常用场景

### 创建新项目
> "帮我创建一个现代的 React 管理后台界面"
> "用 Vue 3 做一个电商首页，要求独特的设计风格"

### 组件开发
> "实现一个支持拖拽的 Kanban 看板组件"
> "创建一个带动画的无限滚动列表"

### UI 优化
> "优化这个页面的 Core Web Vitals 分数"
> "把这个页面改成响应式布局"

### 设计系统
> "帮我建立一套设计系统，包含按钮、表单、卡片等组件"
> "用 Tailwind CSS 实现一个组件库"

## 代码规范

### 组件结构
```typescript
// 清晰的组件结构
interface ComponentProps {
  title: string;
  onClick?: () => void;
}

// 完整的 PropTypes 定义
export function Component({ title, onClick }: ComponentProps) {
  return <button onClick={onClick}>{title}</button>;
}
```

### 样式规范
```css
/* 使用 CSS Variables */
:root {
  --primary-color: #3b82f6;
  --spacing-unit: 4px;
}

/* BEM 命名或 CSS Modules */
.card__header {
  padding: calc(var(--spacing-unit) * 3);
}
```

### 性能最佳实践
```typescript
// 组件懒加载
const HeavyComponent = lazy(() => import('./HeavyComponent'));

// 依赖优化
import { useMemo, useCallback } from 'react';

// 虚拟列表
import { FixedSizeList } from 'react-window';
```

## 资源推荐

### UI 库
- Radix UI - 无样式、可访问的组件
- Headless UI - Tailwind CSS 官方
- shadcn/ui - 可复制粘贴的组件
- Chakra UI - 开发友好的组件库

### 动画库
- Framer Motion - React 首选
- GSAP - 强大的动画引擎
- Lottie - 设计动画实现
- Motion One - 现代 Web 动画

### 设计工具
- Figma - 设计与协作
- Tailwind CSS - 原子化 CSS
- Storybook - 组件文档
- Storyblok - CMS 集成

## 适用人群

- 需要高质量前端界面的开发者
- 想要避免模板化设计的团队
- 追求性能和可维护性的项目
- 需要设计系统支持的企业

## 与其他技能的关系

- **frontend-design** - 官方技能，类似但更偏向设计
- **web-artisan** - 全栈 Web 开发
- **superpowers** - 可配合使用，提升开发流程

## 示例请求

> "创建一个类似 Linear 的项目管理界面"
> "用 React + Tailwind 实现一个现代的仪表盘"
> "优化这个电商网站的 LCP 分数到 2.5s 以下"
> "设计一个深色主题的代码编辑器界面"
