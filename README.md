<p align="center">
  <h1 align="center">🎙️ AirText</h1>
  <p align="center"><strong>Voice-to-text input for macOS — Hold Fn, speak, release, done.</strong></p>
  <p align="center">
    <a href="README.md">English</a> · <a href="docs/README_zh-CN.md">简体中文</a> · <a href="docs/README_zh-TW.md">繁體中文</a> · <a href="docs/README_ja.md">日本語</a> · <a href="docs/README_ko.md">한국어</a>
  </p>
</p>

---

AirText is a lightweight macOS menu bar application that lets you input text by voice anywhere on your Mac. Simply hold the **Fn** key, speak, and the transcribed text is automatically pasted into the currently focused text field.

## ✨ Features

- **🎤 Hold-to-talk** — Hold Fn to record, release to transcribe and paste
- **⚡ Real-time streaming** — See live transcription as you speak
- **🌊 Waveform animation** — Elegant floating panel with real-time audio visualization
- **🌍 5 languages supported** — English, 简体中文, 繁體中文, 日本語, 한국어
- **🤖 LLM refinement** (optional) — Auto-correct speech recognition errors via OpenAI-compatible API
- **📋 Smart paste** — Automatically handles CJK input method switching and clipboard restoration
- **🪶 Lightweight** — Menu bar app, no Dock icon, minimal resource usage

## 📋 Requirements

- **macOS 14.0** (Sonoma) or later
- **Swift 5.9** or later
- **Xcode Command Line Tools** (for building)

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/your-username/airtext-mac.git
cd airtext-mac
```

### 2. Build

```bash
# Debug build (faster, recommended for first run)
make debug

# Release build (optimized)
make build
```

### 3. Run

```bash
# Run the app
make run-debug
```

Or double-click `AirText.app` in the project directory.

### 4. Grant permissions

On first launch, macOS will ask you to grant the following permissions:

| Permission | Purpose | Where to grant |
|---|---|---|
| **Microphone** | Audio recording | System Settings → Privacy & Security → Microphone |
| **Speech Recognition** | Voice-to-text | System Settings → Privacy & Security → Speech Recognition |
| **Accessibility** | Global Fn key listening | System Settings → Privacy & Security → Accessibility |

> ⚠️ **Important**: You must grant **all three permissions** for AirText to work properly. After granting Accessibility permission, you may need to restart the app.

### 5. Use it!

1. Look for the **waveform icon** (🎵) in your menu bar
2. Click on any text field in any app
3. **Hold Fn** — a floating panel appears with waveform animation
4. **Speak** — you'll see real-time transcription
5. **Release Fn** — text is automatically pasted

## 🛠️ Installation

To install AirText to your Applications folder:

```bash
make install
```

To uninstall:

```bash
make uninstall
```

## ⚙️ Configuration

### Language

Click the menu bar icon → **Language** → Select your preferred language:

- English (en-US)
- 简体中文 (zh-CN) — *default*
- 繁體中文 (zh-TW)
- 日本語 (ja-JP)
- 한국어 (ko-KR)

### LLM Refinement (Optional)

AirText supports optional LLM-based text correction to fix common speech recognition errors (e.g., homophones, technical terms).

1. Click the menu bar icon → **LLM Refinement** → **Settings...**
2. Enter your API details:
   - **Base URL**: OpenAI-compatible API endpoint (default: `https://api.openai.com/v1`)
   - **API Key**: Your API key
   - **Model**: Model name (default: `gpt-4o-mini`)
3. Click **Test Connection** to verify
4. Enable via menu bar icon → **LLM Refinement** → **Enable**

> 💡 Any OpenAI-compatible API works (OpenAI, Ollama, LM Studio, etc.)

## 📁 Project Structure

```
airtext-mac/
├── Package.swift              # Swift Package Manager config
├── Makefile                   # Build, run, install commands
├── Resources/
│   └── Info.plist             # App metadata & permissions
└── Sources/AirText/
    ├── Main.swift             # App entry point
    ├── AppDelegate.swift      # App lifecycle & orchestration
    ├── Core/
    │   ├── AudioEngine.swift            # Real-time audio recording
    │   ├── AutoLanguageDetector.swift   # Parallel language auto-detection
    │   ├── KeyboardMonitor.swift        # Global Fn key listener
    │   ├── SpeechRecognizer.swift       # Apple Speech framework wrapper
    │   └── TextInjector.swift           # Smart clipboard paste
    ├── Services/
    │   ├── LLMService.swift        # OpenAI-compatible LLM client
    │   └── SettingsManager.swift   # UserDefaults persistence
    ├── UI/
    │   ├── FloatingPanel.swift          # Floating transcription panel
    │   ├── FloatingContentView.swift    # Panel content layout
    │   ├── WaveformView.swift           # Real-time waveform animation
    │   ├── StatusBarMenu.swift          # Menu bar interface
    │   └── SettingsWindowController.swift # LLM settings window
    └── Extensions/
        ├── CGEvent+Extensions.swift     # CGEvent helpers
        └── NSColor+Extensions.swift     # Color utilities
```

## 🔧 Make Commands

| Command | Description |
|---|---|
| `make build` | Build release version |
| `make debug` | Build debug version (faster) |
| `make run` | Build release and run |
| `make run-debug` | Build debug and run |
| `make install` | Install to /Applications |
| `make uninstall` | Remove from /Applications |
| `make clean` | Remove all build artifacts |
| `make help` | Show all available commands |

## 🔒 Privacy & Security

- **No data collection** — All speech recognition is processed locally via Apple's Speech framework
- **No hardcoded credentials** — API keys are entered by the user and stored locally
- **LLM is optional** — The app works fully offline without LLM configuration
- **Open source** — Full source code available for review

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
