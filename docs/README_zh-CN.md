<p align="center">
  <h1 align="center">🎙️ AirText</h1>
  <p align="center"><strong>macOS 语音输入工具 — 按住 Fn，说话，松开，完成。</strong></p>
  <p align="center">
    <a href="../README.md">English</a> · <a href="README_zh-CN.md">简体中文</a> · <a href="README_zh-TW.md">繁體中文</a> · <a href="README_ja.md">日本語</a> · <a href="README_ko.md">한국어</a>
  </p>
</p>

---

AirText 是一款轻量级 macOS 菜单栏应用，让你可以在 Mac 上的任何地方通过语音输入文字。只需按住 **Fn** 键说话，松开后转录文字会自动粘贴到当前光标所在的输入框。

## ✨ 功能特色

- **🎤 按住说话** — 按住 Fn 录音，松开自动转录并粘贴
- **⚡ 实时流式识别** — 说话时实时显示转录文字
- **🌊 波形动画** — 优雅的悬浮面板，实时音频可视化
- **🌍 支持 5 种语言** — English、简体中文、繁體中文、日本語、한국어
- **🤖 LLM 智能校正**（可选）— 通过 OpenAI 兼容 API 自动纠正语音识别错误
- **📋 智能粘贴** — 自动处理 CJK 输入法切换和剪贴板恢复
- **🪶 轻量运行** — 菜单栏应用，无 Dock 图标，资源占用极少

## 📋 系统要求

- **macOS 14.0**（Sonoma）或更高版本
- **Swift 5.9** 或更高版本
- **Xcode 命令行工具**（用于编译）

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/your-username/airtext-mac.git
cd airtext-mac
```

### 2. 编译

```bash
# 调试版本（更快，推荐首次运行使用）
make debug

# 发布版本（已优化）
make build
```

### 3. 运行

```bash
# 运行应用
make run-debug
```

或直接双击项目目录中的 `AirText.app`。

### 4. 授予权限

首次启动时，macOS 会要求你授予以下权限：

| 权限 | 用途 | 设置位置 |
|---|---|---|
| **麦克风** | 音频录制 | 系统设置 → 隐私与安全性 → 麦克风 |
| **语音识别** | 语音转文字 | 系统设置 → 隐私与安全性 → 语音识别 |
| **辅助功能** | 全局 Fn 键监听 | 系统设置 → 隐私与安全性 → 辅助功能 |

> ⚠️ **重要提示**：你必须授予**全部三项权限**，AirText 才能正常工作。授予辅助功能权限后，可能需要重启应用。

### 5. 开始使用！

1. 在菜单栏中找到**波形图标**（🎵）
2. 点击任意应用中的文本输入框
3. **按住 Fn** — 悬浮面板出现，显示波形动画
4. **说话** — 实时显示转录文字
5. **松开 Fn** — 文字自动粘贴到输入框

## 🛠️ 安装

将 AirText 安装到应用程序文件夹：

```bash
make install
```

卸载：

```bash
make uninstall
```

## ⚙️ 设置

### 语言切换

点击菜单栏图标 → **Language** → 选择你的语言：

- English (en-US)
- 简体中文 (zh-CN) — *默认*
- 繁體中文 (zh-TW)
- 日本語 (ja-JP)
- 한국어 (ko-KR)

### LLM 智能校正（可选）

AirText 支持可选的 LLM 文本校正功能，可以修复常见的语音识别错误（如同音字、技术术语等）。

1. 点击菜单栏图标 → **LLM Refinement** → **Settings...**
2. 填入 API 信息：
   - **Base URL**：OpenAI 兼容 API 地址（默认：`https://api.openai.com/v1`）
   - **API Key**：你的 API 密钥
   - **Model**：模型名称（默认：`gpt-4o-mini`）
3. 点击 **Test Connection** 验证连接
4. 通过菜单栏图标 → **LLM Refinement** → **Enable** 启用

> 💡 任何 OpenAI 兼容的 API 都可以使用（OpenAI、Ollama、LM Studio 等）

## 🔧 Make 命令

| 命令 | 说明 |
|---|---|
| `make build` | 构建发布版本 |
| `make debug` | 构建调试版本（更快） |
| `make run` | 构建发布版本并运行 |
| `make run-debug` | 构建调试版本并运行 |
| `make install` | 安装到 /Applications |
| `make uninstall` | 从 /Applications 卸载 |
| `make clean` | 清除所有构建产物 |
| `make help` | 显示所有可用命令 |

## 🔒 隐私与安全

- **不收集数据** — 所有语音识别均通过 Apple Speech 框架在本地处理
- **无硬编码凭据** — API 密钥由用户输入并存储在本地
- **LLM 是可选的** — 不配置 LLM 也能完整使用
- **开源** — 完整源代码可供审查

## 📄 许可证

MIT License — 详见 [LICENSE](../LICENSE)。
