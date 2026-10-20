# 倒班助手 — TrollStore 构建包（免 Mac / 免证书）

本包是在原始源码基础上修复了构建障碍后的可构建版本：

## 相对原始源码的修复
1. `Info.plist` 补齐 `CFBundleShortVersionString` / `CFBundleVersion` /
   `CFBundleExecutable` / `LSRequiresIPhoneOS`（原文件缺版本键，不补无法打包安装）
2. `SettingsScreen.swift` 中 `JSONEncoder.pretty`（非标准 API）改为标准写法
3. 新增共享 Scheme：`ShiftAssistantComplete.xcodeproj/xcshareddata/xcschemes/ShiftAssistantComplete.xcscheme`

## 方案 A：GitHub Actions 构建（无需 Mac，约 5 分钟）

1. 注册/登录 GitHub，新建一个**私有或公开仓库**（如 `ShiftAssistant`）
2. 把本包根目录下的全部内容上传到仓库（即仓库根目录直接包含
   `ShiftAssistantComplete.xcodeproj/`、`ShiftAssistantComplete/`、`.github/`），
   网页上传即可，不需要装任何软件
3. 打开仓库的 **Actions** 标签 → 左侧选择 **Build TIPA for TrollStore**
   → 右侧 **Run workflow** → 再点一次 **Run workflow**
4. 等约 5 分钟（绿色对勾后），点进该次运行 → 页面底部 **Artifacts**
   → 下载 **ShiftAssistant-TrollStore**
5. 解压得到 `ShiftAssistant.tipa` / `ShiftAssistant.ipa`

> 构建为未签名包（CODE_SIGNING_ALLOWED=NO），不需要 Apple ID，
> TrollStore 安装时会自动完成签名。

## 方案 B：本地 Mac 构建（可选）

```bash
bash build-local.sh
# 产物：build/ShiftAssistant.tipa
```

## 安装到 TrollStore

把 `.tipa` 传到 iPhone 后任选其一：
- 文件 App 中长按该文件 → 共享 → **用 TrollStore 打开** → Install
- 或 TrollStore → Settings → **Install from URL**（需先把 tipa 放到可访问的直链）

## 系统要求

- 设备系统需 **iOS 16.0 或更高**（代码使用了 iOS 16 的 NavigationStack / ShareLink 等 API）
- TrollStore 支持 iOS 15.0–16.6.1 与 17.0，故 16.x 的巨魔设备均可安装

## 常见问题

- **Actions 页面看不到工作流**：workflow 文件推送到默认分支（main）后才会出现；
  且首次使用需点 Actions 页面的绿色按钮授权
- **构建报错**：把 Actions 日志贴出来排查。源码为原型，可能存在个别编译问题
- **需要 iOS 15 也能跑**：需把 NavigationStack 降级为 NavigationView 等改造，
  工作量较大，如有需要可再提出
