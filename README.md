# Daymark · Flutter 任务管理

一款简洁的离线优先任务管理 App，使用 **Flutter + Material 3 + SharedPreferencesAsync** 构建，不依赖后端服务。

## 功能

- 新建、编辑、删除、完成/取消完成任务，删除后支持撤销
- 工作 / 生活 / 学习 / 健康 / 其他分类
- 高 / 中 / 低优先级、可选截止日期、逾期提示
- 全部任务、今天（含逾期）、即将到期、重要任务、已完成视图
- 标题和备注搜索、分类及优先级筛选
- 完成率进度展示、任务汇总
- 自适应桌面侧边栏和移动端抽屉布局
- Material 3 浅色与深色主题（保存偏好）
- 使用 `shared_preferences` 保存任务，完全离线可用
- 首次打开提供 6 条可编辑/删除的演示任务；删除后不会自动重新生成

## 环境要求

- Flutter 3.35 或更新版本（Dart 3.9 或更新版本）
- Windows、macOS、Linux、Android、iOS 或 Web 所需的 Flutter 工具链

## 运行

此压缩包包含**完整的业务源码、依赖配置和单元测试**。由于构建环境未安装 Flutter SDK，未附带由 Flutter CLI 自动生成的 `android/`、`ios/`、`windows/`、`macos/`、`linux/`、`web/` 平台目录。

解压后，在项目根目录运行：

```bash
# 使用本机 Flutter SDK 生成平台工程；已有 lib 文件不会被覆盖
flutter create --project-name daymark_flutter .

# 下载依赖
flutter pub get

# 检查环境和可用设备
flutter doctor
flutter devices

# 在当前设备运行；也可指定 -d windows / -d macos / -d chrome / -d android
flutter run
```

Windows 桌面首次运行如果未启用桌面支持，可先执行 `flutter config --enable-windows-desktop`；Web 可使用 `flutter run -d chrome`。原生平台构建需要安装对应 SDK（例如 Windows 的 Visual Studio C++ 工具链，iOS 的 Xcode）。

### 测试与构建

```bash
flutter analyze
flutter test
flutter build windows  # 或 flutter build apk / web / macos
```

## 目录结构

```text
daymark_flutter/
├── lib/
│   ├── main.dart                  # 程序入口
│   ├── app.dart                   # 应用主题和初始化
│   ├── models/task_item.dart      # 任务模型、枚举、序列化
│   ├── data/task_repository.dart  # 本地持久化
│   ├── state/
│   │   ├── task_controller.dart   # CRUD、撤销、顺序写入
│   │   └── task_filter.dart       # 视图、查询与排序
│   └── ui/
│       ├── task_home_page.dart    # 桌面 / 移动端任务页
│       └── widgets/task_editor.dart # 新建 / 编辑任务
├── test/
│   ├── task_item_test.dart
│   └── task_filter_test.dart
├── pubspec.yaml
└── analysis_options.yaml
```

## 数据说明

所有任务保存在当前设备的应用私有存储（Web 则为浏览器本地存储），**不会自动同步到其他设备**。当前版本使用轻量 JSON 序列化，适合个人小型待办列表；若以后需要上万任务、附件、复杂搜索或同步，推荐迁移到 SQLite/Drift 并增加导入导出、云同步功能。

## 后续扩展建议

提醒通知、重复任务、子任务、拖拽排序、日历视图、数据导出，以及可选的端到端加密云同步。

> 说明：项目源代码已生成并做静态检查，但因当前环境缺少 Flutter / Dart CLI，无法在此执行 `flutter analyze`、`flutter test` 或启动实际 App；请在安装 Flutter 的开发环境中进行最终编译验证。
