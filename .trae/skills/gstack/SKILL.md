---
name: gstack
description: YC CEO 开源的 AI 软件工厂，将 AI 转变为虚拟工程团队，包含 23 个专业角色（CEO、设计师、工程经理、QA负责人、安全官等）
---

# GStack - 虚拟工程团队

## 功能说明

GStack 将 Claude Code 转变为虚拟工程团队，通过 23 个专业角色和 8 个强大工具，让一个人的 coding 效率媲美一个 20 人的技术团队。

**创始人**: Garry Tan (Y Combinator CEO)
**Star**: 93,788+
**定位**: "AI 软件工厂"

## 核心理念

- **角色专业化** - 每个角色各司其职
- **团队协作** - 通过 Slash 命令调用不同专家
- **效率倍增** - 单人可完成整个技术团队的工作
- **YC 背书** - 顶级创业孵化器的工程实践

## 23 个专业角色

### 管理层
- **CEO** - 战略审查、方向把控
- **CTO** - 技术架构决策
- **Eng Manager** - 工程管理、进度协调
- **Product Manager** - 产品需求、优先级排序

### 设计层
- **Designer** - 设计系统、UI/UX
- **UX Researcher** - 用户体验研究
- **Design Reviewer** - 设计审查

### 工程层
- **Backend Engineer** - 后端开发
- **Frontend Engineer** - 前端开发
- **Full Stack Engineer** - 全栈开发
- **DevOps Engineer** - 运维、部署
- **Security Engineer** - 安全审查
- **QA Engineer** - 质量保证
- **QA Lead** - QA 负责人

### 专业领域
- **Data Engineer** - 数据工程
- **ML Engineer** - 机器学习
- **Mobile Engineer** - 移动端开发
- **iOS Engineer** - iOS 开发
- **Android Engineer** - Android 开发

### 工具与支持
- **Code Reviewer** - 代码审查
- **Documentation Writer** - 文档编写
- **API Designer** - API 设计
- **Database Architect** - 数据库架构

## 8 个强大工具

1. **浏览器工具** - 网页浏览和数据抓取
2. **文件管理** - 项目文件操作
3. **Git 操作** - 版本控制
4. **终端工具** - 命令行执行
5. **搜索工具** - 代码和文档搜索
6. **测试工具** - 自动化测试
7. **部署工具** - 应用部署
8. **监控工具** - 性能和日志监控

## 使用方式

### Slash 命令调用
```
/ceo          - 战略审查
/designer     - 设计咨询
/eng-manager  - 工程管理
/qa           - 质量保证
/security     - 安全审查
```

### 场景示例

**启动新项目**:
```
/ceo "帮我审查这个创业想法的可行性"
/designer "设计一个现代化的仪表盘界面"
```

**开发阶段**:
```
/backend "实现用户认证 API"
/frontend "实现登录页面"
/qa "为登录流程编写测试"
```

**审查阶段**:
```
/security "审查整个认证流程的安全性"
/code-reviewer "审查最近提交的代码"
```

## 适用场景

- 独立开发者或小型团队
- 需要快速构建完整产品
- 想要专业级的工程实践
- 创业公司快速迭代
- 需要多领域专家协作

## 效率对比

**传统方式**: 20 人团队 × 几个月
**使用 GStack**: 1 人 × 60 天 → 3 个生产服务 + 40+ 功能

## 安装来源

Claude Code:
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install gstack@gstack-marketplace
```

或在 Claude Code 官方插件市场搜索 "gstack"

## 与 Superpowers 的区别

- **Superpowers**: 专注于工程纪律和流程规范（测试驱动、系统化调试）
- **GStack**: 专注于角色扮演和团队协作（23 个专家角色）
- **推荐**: 可以同时使用，互为补充

## 使用建议

1. 从 CEO 或 Eng Manager 开始，明确项目方向
2. 在设计阶段调用 Designer 和 UX Researcher
3. 开发阶段并行调用多个工程师角色
4. 每个阶段都进行代码审查和安全审查
5. QA 负责人确保质量标准
