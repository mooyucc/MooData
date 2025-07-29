# MooData - 项目数据管理应用

## 📱 应用简介

MooData 是一款专为 macOS 平台设计的现代化项目数据管理应用，采用 SwiftUI 框架开发。应用提供了直观的项目管理界面，支持设计指标数据录入、分析和导出功能。

## ✨ 主要功能

### 🎯 项目管理
- **项目创建与管理**：支持创建多个项目，每个项目可设置名称、颜色和分组
- **项目分组**：将相关项目组织到不同分组中，便于分类管理
- **拖拽排序**：支持项目间的拖拽排序和分组调整
- **搜索功能**：快速搜索和筛选项目

### 📊 设计指标管理
- **指标数据录入**：支持多种类型的设计指标数据输入
- **数据可视化**：直观展示项目指标数据
- **数据导出**：支持 CSV 格式数据导出
- **数据导入**：支持从 CSV 文件导入数据

### 🎨 用户界面
- **现代化设计**：采用 SwiftUI 构建的现代化界面
- **深色模式**：支持浅色/深色主题切换
- **响应式布局**：适配不同屏幕尺寸
- **触觉反馈**：支持 macOS 触觉反馈

### 💾 数据管理
- **本地存储**：使用 UserDefaults 进行本地数据存储
- **文件导入导出**：支持 JSON 格式的项目数据导入导出
- **数据备份**：支持项目数据的备份和恢复

## 🏗️ 技术架构

### 开发环境
- **平台**：macOS
- **框架**：SwiftUI + AppKit
- **语言**：Swift 5.9+
- **最低系统要求**：macOS 13.0+

### 项目结构
```
MooData/
├── MooData/                    # 主应用目录
│   ├── Assets.xcassets/       # 应用资源文件
│   ├── Extensions/            # Swift 扩展
│   ├── Models/                # 数据模型
│   ├── Utils/                 # 工具类
│   ├── ViewModels/            # 视图模型
│   ├── Views/                 # 视图组件
│   │   ├── Auth/             # 认证相关视图
│   │   └── ...               # 其他视图组件
│   ├── Resources/             # 本地化资源
│   └── MooDataApp.swift      # 应用入口
├── MooData.xcodeproj/         # Xcode 项目文件
├── MooDataTests/              # 单元测试
├── MooDataUITests/            # UI 测试
└── scripts/                   # 构建脚本
```

### 核心模块

#### 数据模型 (`Models/`)
- `Project.swift` - 项目数据模型
- `ProjectData.swift` - 项目数据结构
- `User.swift` - 用户数据模型
- `AuthService.swift` - 认证服务

#### 视图模型 (`ViewModels/`)
- `ProjectViewModel.swift` - 项目管理逻辑
- `AuthViewModel.swift` - 用户认证逻辑

#### 视图组件 (`Views/`)
- `ContentView.swift` - 主内容视图
- `DataView.swift` - 数据视图
- `IndicatorCardView.swift` - 指标卡片组件
- `AuthenticationView.swift` - 认证视图

#### 工具类 (`Utils/`)
- `Color+Hex.swift` - 颜色工具扩展
- `IndicatorCalculator.swift` - 指标计算工具

## 🚀 快速开始

### 环境要求
- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9+

### 安装步骤
1. 克隆项目到本地
```bash
git clone [项目地址]
cd MooData
```

2. 使用 Xcode 打开项目
```bash
open MooData.xcodeproj
```

3. 选择目标设备为 macOS
4. 点击运行按钮或使用快捷键 `Cmd + R` 启动应用

### 构建项目
```bash
# 构建 Debug 版本
xcodebuild -project MooData.xcodeproj -scheme MooData -configuration Debug build

# 构建 Release 版本
xcodebuild -project MooData.xcodeproj -scheme MooData -configuration Release build
```

## 📋 功能特性详解

### 项目管理
- **项目创建**：点击 "+" 按钮创建新项目，设置名称、颜色和分组
- **项目编辑**：双击项目卡片进入编辑模式
- **项目删除**：在编辑模式下选择项目进行删除
- **项目排序**：拖拽项目卡片调整顺序

### 数据管理
- **指标录入**：在数据视图中录入各种设计指标
- **数据验证**：实时验证数据输入的有效性
- **自动计算**：支持基于输入数据的自动计算功能
- **数据导出**：将指标数据导出为 CSV 格式

### 文件操作
- **打开文件**：支持打开 JSON 格式的项目数据文件
- **保存文件**：将当前项目数据保存为 JSON 文件
- **另存为**：将数据保存到新文件位置
- **关闭文件**：关闭当前打开的数据文件

## 🎨 界面设计

### 设计原则
- **简洁性**：界面简洁明了，减少视觉干扰
- **一致性**：保持界面元素的一致性
- **可访问性**：支持系统辅助功能
- **响应性**：界面响应迅速，提供即时反馈

### 颜色系统
- **主色调**：使用项目自定义颜色
- **辅助色**：灰色系用于次要信息
- **状态色**：绿色表示成功，红色表示错误
- **背景色**：支持浅色/深色主题

## 🔧 开发指南

### 代码规范
- 遵循 Swift 官方编码规范
- 使用有意义的变量和函数命名
- 添加适当的注释和文档
- 保持代码的可读性和可维护性

### 架构模式
- **MVVM**：使用 Model-View-ViewModel 架构
- **响应式编程**：使用 SwiftUI 的响应式特性
- **数据绑定**：通过 @State、@Binding 等属性包装器实现数据绑定

### 测试策略
- **单元测试**：测试业务逻辑和数据模型
- **UI 测试**：测试用户界面交互
- **集成测试**：测试模块间的协作

## 📝 更新日志

详细的更新日志请查看 [CHANGELOG.md](./CHANGELOG.md) 文件。

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系方式

- 项目维护者：徐化军
- 邮箱：[联系邮箱]
- 项目地址：[项目仓库地址]

## 🙏 致谢

感谢所有为这个项目做出贡献的开发者和用户。

---

**注意**：本项目专为 macOS 平台开发，不支持 iOS 或其他平台。 