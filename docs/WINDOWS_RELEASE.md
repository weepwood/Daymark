# Daymark · Windows 安装包构建与发布

本仓库通过 GitHub Actions，在 Windows Server 2022 Runner 上使用 Flutter 3.47.9 编译 Windows x64 桌面应用，并通过 Inno Setup 6 生成安装包。

## 构建产物

| 文件 | 说明 |
| --- | --- |
| `Daymark-Setup-x.y.z-windows-x64.exe` | 安装版，包含卸载功能、开始菜单快捷方式和可选桌面快捷方式 |
| `Daymark-x.y.z-windows-x64-portable.zip` | 免安装版，解压后运行 Daymark.exe |
| `SHA256SUMS.txt` | 安装包和便携版 SHA-256 校验值 |

版本从 pubspec.yaml 读取。例如 `version: 1.1.0+2` 对应安装包版本 `1.1.0`。

**Flutter Windows 无法只分发单个程序 exe。** 必须携带 Release 目录中的所有 DLL 和 data 目录。流水线已将所需的 Flutter 文件和 3 个 Visual C++ 应用本地运行库一并封装。

## 下载日常构建

1. 提交 PR、向 main 推送代码，或在 GitHub Actions 手动执行 “Windows 安装包构建与发布”。
2. 打开成功运行的 Actions 页面。
3. 从 Artifacts 下载 `Daymark-Windows-<运行编号>`。
4. 解压 Artifact 后得到安装包、便携版和 SHA-256 校验文件。GitHub Artifact 本身是下载容器，而非安装包。

日常产物保留 30 天，不会自动创建公开 Release。

## 发布正式版本

1. 确认 main 分支构建及测试通过。
2. 修改并提交 pubspec.yaml 中的版本号（例如 `version: 1.1.0+2`）。
3. 在 main 当前提交打标签并推送：

```bash
git checkout main
git pull --ff-only
git tag v1.1.0
git push origin v1.1.0
```

4. Windows 工作流会校验 tag 的版本必须等于 pubspec.yaml 中的 x.y.z，运行测试、构建安装包，并自动上传至 GitHub Releases。

正式版本地址：https://github.com/weepwood/Daymark/releases

**重要：** 不能在构建失败前假定安装包已经发布。请在 Actions 中确认 Windows job 和 Release job 都成功。

## 本地构建

安装 Flutter 3.47.9、Visual Studio 2022 C++ 桌面工具链与 Inno Setup 6 后执行：

```powershell
flutter config --enable-windows-desktop
flutter create --platforms=windows --project-name daymark_flutter --org com.weepwood .
flutter pub get
flutter test
```

修改 `windows/CMakeLists.txt` 中的 `set(BINARY_NAME "daymark_flutter")` 为 `set(BINARY_NAME "Daymark")`，同时建议将 `windows/runner/main.cpp` 以及 `windows/runner/Runner.rc` 中的应用名改为 Daymark，再执行：

```powershell
flutter build windows --release
```

将 x64 VC++ 运行库 `msvcp140.dll`、`vcruntime140.dll`、`vcruntime140_1.dll` 复制到 `build/windows/x64/runner/Release`。再通过 Inno Setup 6 的 ISCC.exe 编译：

```powershell
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' /DAppVersion=1.1.0 installer\daymark.iss
```

得到的安装包位于 `dist/`。

## 当前发布限制

- 目前仅构建 Windows x64；Arm64 Windows 11 依赖操作系统的 x64 仿真，尚未专门测试。
- 安装包尚未进行 Authenticode 数字签名，SmartScreen 可能显示“未知发布者”。面向公众长期分发时建议增加可信证书签名。
- CI 已覆盖单元测试与编译，但尚未执行真实用户桌面的安装、启动、卸载 GUI 冒烟测试。
- 目前没有自动更新功能。任务保存在本地应用私有目录，卸载程序不会主动删除任务数据。

## 相关文件

- `.github/workflows/windows-release.yml`：Windows 自动构建与 Release
- `installer/daymark.iss`：Inno Setup 安装配置
- `pubspec.yaml`：Flutter 版本和应用版本
