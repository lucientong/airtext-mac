<p align="center">
  <h1 align="center">🎙️ AirText</h1>
  <p align="center"><strong>macOS 語音輸入工具 — 按住 Fn，說話，鬆開，完成。</strong></p>
  <p align="center">
    <a href="../README.md">English</a> · <a href="README_zh-CN.md">简体中文</a> · <a href="README_zh-TW.md">繁體中文</a> · <a href="README_ja.md">日本語</a> · <a href="README_ko.md">한국어</a>
  </p>
</p>

---

AirText 是一款輕量級 macOS 選單列應用程式，讓你可以在 Mac 上的任何地方透過語音輸入文字。只需按住 **Fn** 鍵說話，鬆開後轉錄文字會自動貼上到目前游標所在的輸入框。

## ✨ 功能特色

- **🎤 按住說話** — 按住 Fn 錄音，鬆開自動轉錄並貼上
- **⚡ 即時串流辨識** — 說話時即時顯示轉錄文字
- **🌊 波形動畫** — 優雅的懸浮面板，即時音訊視覺化
- **🌍 支援 5 種語言** — English、简体中文、繁體中文、日本語、한국어
- **🤖 LLM 智慧校正**（選用）— 透過 OpenAI 相容 API 自動修正語音辨識錯誤
- **📋 智慧貼上** — 自動處理 CJK 輸入法切換和剪貼簿恢復
- **🪶 輕量執行** — 選單列應用程式，無 Dock 圖示，資源佔用極少

## 📋 系統需求

- **macOS 14.0**（Sonoma）或更高版本
- **Swift 5.9** 或更高版本
- **Xcode 命令列工具**（用於編譯）

## 🚀 快速開始

### 1. 複製儲存庫

```bash
git clone https://github.com/your-username/airtext-mac.git
cd airtext-mac
```

### 2. 編譯

```bash
# 除錯版本（較快，建議首次執行使用）
make debug

# 發行版本（已最佳化）
make build
```

### 3. 執行

```bash
# 執行應用程式
make run-debug
```

或直接雙擊專案目錄中的 `AirText.app`。

### 4. 授予權限

首次啟動時，macOS 會要求你授予以下權限：

| 權限 | 用途 | 設定位置 |
|---|---|---|
| **麥克風** | 音訊錄製 | 系統設定 → 隱私權與安全性 → 麥克風 |
| **語音辨識** | 語音轉文字 | 系統設定 → 隱私權與安全性 → 語音辨識 |
| **輔助使用** | 全域 Fn 鍵監聽 | 系統設定 → 隱私權與安全性 → 輔助使用 |

> ⚠️ **重要提示**：你必須授予**全部三項權限**，AirText 才能正常運作。授予輔助使用權限後，可能需要重新啟動應用程式。

### 5. 開始使用！

1. 在選單列中找到**波形圖示**（🎵）
2. 點擊任意應用程式中的文字輸入框
3. **按住 Fn** — 懸浮面板出現，顯示波形動畫
4. **說話** — 即時顯示轉錄文字
5. **鬆開 Fn** — 文字自動貼上到輸入框

## 🛠️ 安裝

將 AirText 安裝到應用程式資料夾：

```bash
make install
```

解除安裝：

```bash
make uninstall
```

## ⚙️ 設定

### 語言切換

點擊選單列圖示 → **Language** → 選擇你的語言：

- English (en-US)
- 简体中文 (zh-CN) — *預設*
- 繁體中文 (zh-TW)
- 日本語 (ja-JP)
- 한국어 (ko-KR)

### LLM 智慧校正（選用）

AirText 支援選用的 LLM 文字校正功能，可以修正常見的語音辨識錯誤（如同音字、技術術語等）。

1. 點擊選單列圖示 → **LLM Refinement** → **Settings...**
2. 填入 API 資訊：
   - **Base URL**：OpenAI 相容 API 位址（預設：`https://api.openai.com/v1`）
   - **API Key**：你的 API 金鑰
   - **Model**：模型名稱（預設：`gpt-4o-mini`）
3. 點擊 **Test Connection** 驗證連線
4. 透過選單列圖示 → **LLM Refinement** → **Enable** 啟用

> 💡 任何 OpenAI 相容的 API 都可以使用（OpenAI、Ollama、LM Studio 等）

## 🔧 Make 指令

| 指令 | 說明 |
|---|---|
| `make build` | 建置發行版本 |
| `make debug` | 建置除錯版本（較快） |
| `make run` | 建置發行版本並執行 |
| `make run-debug` | 建置除錯版本並執行 |
| `make install` | 安裝到 /Applications |
| `make uninstall` | 從 /Applications 解除安裝 |
| `make clean` | 清除所有建置產物 |
| `make help` | 顯示所有可用指令 |

## 🔒 隱私權與安全性

- **不收集資料** — 所有語音辨識均透過 Apple Speech 框架在本機處理
- **無硬編碼憑證** — API 金鑰由使用者輸入並儲存在本機
- **LLM 是選用的** — 不設定 LLM 也能完整使用
- **開放原始碼** — 完整原始碼可供審查

## 📄 授權條款

MIT License — 詳見 [LICENSE](../LICENSE)。
