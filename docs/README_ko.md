<p align="center">
  <h1 align="center">🎙️ AirText</h1>
  <p align="center"><strong>macOS 음성 입력 도구 — Fn을 누르고, 말하고, 놓으면 끝.</strong></p>
  <p align="center">
    <a href="../README.md">English</a> · <a href="README_zh-CN.md">简体中文</a> · <a href="README_zh-TW.md">繁體中文</a> · <a href="README_ja.md">日本語</a> · <a href="README_ko.md">한국어</a>
  </p>
</p>

---

AirText는 가벼운 macOS 메뉴 막대 앱으로, Mac 어디에서나 음성으로 텍스트를 입력할 수 있습니다. **Fn** 키를 누른 상태에서 말하면, 변환된 텍스트가 현재 포커스된 입력 필드에 자동으로 붙여넣기 됩니다.

## ✨ 기능

- **🎤 누르고 말하기** — Fn을 눌러 녹음, 놓으면 자동 변환 및 붙여넣기
- **⚡ 실시간 스트리밍** — 말하는 동안 실시간으로 변환 텍스트 표시
- **🌊 파형 애니메이션** — 실시간 오디오 시각화가 있는 우아한 플로팅 패널
- **🌍 5개 언어 지원** — English, 简体中文, 繁體中文, 日本語, 한국어
- **🤖 LLM 텍스트 보정** (선택 사항) — OpenAI 호환 API로 음성 인식 오류 자동 수정
- **📋 스마트 붙여넣기** — CJK 입력기 전환 및 클립보드 복원 자동 처리
- **🪶 가볍고 효율적** — 메뉴 막대 앱, Dock 아이콘 없음, 최소한의 리소스 사용

## 📋 시스템 요구 사항

- **macOS 14.0** (Sonoma) 이상
- **Swift 5.9** 이상
- **Xcode 명령줄 도구** (빌드용)

## 🚀 빠른 시작

### 1. 저장소 클론

```bash
git clone https://github.com/your-username/airtext-mac.git
cd airtext-mac
```

### 2. 빌드

```bash
# 디버그 빌드 (더 빠름, 첫 실행에 권장)
make debug

# 릴리스 빌드 (최적화됨)
make build
```

### 3. 실행

```bash
# 앱 실행
make run-debug
```

또는 프로젝트 디렉토리의 `AirText.app`을 더블 클릭하세요.

### 4. 권한 부여

처음 실행 시 macOS가 다음 권한을 요청합니다:

| 권한 | 용도 | 설정 위치 |
|---|---|---|
| **마이크** | 오디오 녹음 | 시스템 설정 → 개인정보 보호 및 보안 → 마이크 |
| **음성 인식** | 음성을 텍스트로 변환 | 시스템 설정 → 개인정보 보호 및 보안 → 음성 인식 |
| **손쉬운 사용** | 전역 Fn 키 모니터링 | 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용 |

> ⚠️ **중요**: AirText가 올바르게 작동하려면 **세 가지 권한 모두**를 부여해야 합니다. 손쉬운 사용 권한을 부여한 후 앱을 다시 시작해야 할 수 있습니다.

### 5. 사용하기!

1. 메뉴 막대에서 **파형 아이콘** (🎵)을 확인
2. 아무 앱에서 텍스트 입력 필드를 클릭
3. **Fn 누르기** — 파형 애니메이션이 있는 플로팅 패널이 나타남
4. **말하기** — 실시간으로 변환 텍스트가 표시됨
5. **Fn 놓기** — 텍스트가 자동으로 붙여넣기됨

## 🛠️ 설치

AirText를 Applications 폴더에 설치:

```bash
make install
```

제거:

```bash
make uninstall
```

## ⚙️ 설정

### 언어 전환

메뉴 막대 아이콘 클릭 → **Language** → 언어 선택:

- English (en-US)
- 简体中文 (zh-CN) — *기본값*
- 繁體中文 (zh-TW)
- 日本語 (ja-JP)
- 한국어 (ko-KR)

### LLM 텍스트 보정 (선택 사항)

AirText는 선택적 LLM 기반 텍스트 수정을 지원하여 일반적인 음성 인식 오류(동음이의어, 기술 용어 등)를 수정할 수 있습니다.

1. 메뉴 막대 아이콘 클릭 → **LLM Refinement** → **Settings...**
2. API 정보 입력:
   - **Base URL**: OpenAI 호환 API 주소 (기본값: `https://api.openai.com/v1`)
   - **API Key**: API 키
   - **Model**: 모델 이름 (기본값: `gpt-4o-mini`)
3. **Test Connection**을 클릭하여 연결 확인
4. 메뉴 막대 아이콘 → **LLM Refinement** → **Enable**로 활성화

> 💡 OpenAI 호환 API라면 무엇이든 사용 가능합니다 (OpenAI, Ollama, LM Studio 등)

## 🔧 Make 명령어

| 명령어 | 설명 |
|---|---|
| `make build` | 릴리스 버전 빌드 |
| `make debug` | 디버그 버전 빌드 (더 빠름) |
| `make run` | 릴리스 버전 빌드 후 실행 |
| `make run-debug` | 디버그 버전 빌드 후 실행 |
| `make install` | /Applications에 설치 |
| `make uninstall` | /Applications에서 제거 |
| `make clean` | 모든 빌드 결과물 삭제 |
| `make help` | 사용 가능한 명령어 표시 |

## 🔒 개인정보 보호 및 보안

- **데이터 수집 없음** — 모든 음성 인식은 Apple Speech 프레임워크를 통해 로컬에서 처리
- **하드코딩된 자격 증명 없음** — API 키는 사용자가 입력하고 로컬에 저장
- **LLM은 선택 사항** — LLM 설정 없이도 완전히 동작
- **오픈 소스** — 전체 소스 코드 검토 가능

## 📄 라이선스

MIT License — 자세한 내용은 [LICENSE](../LICENSE)를 참조하세요.
