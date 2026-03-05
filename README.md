# openclaw-ollama

OpenClaw + Ollama 단일 컨테이너 배포 스크립트.
API 비용 없이 로컬 LLM(DeepSeek-R1 등)으로 OpenClaw를 운영할 수 있도록 구성한 레포입니다.

---

## 구성

```
[Telegram]
    ↓
[OpenClaw Gateway :8080]
    ↓
[Ollama :11434]
    ↓
[qwen3:8b (로컬 모델)]
```

- **OpenClaw** — 메시징 채널과 LLM을 연결하는 게이트웨이
- **Ollama** — 로컬 LLM 실행 프레임워크. API 키 없이 무료로 사용 가능
- **qwen3:8b** — 기본 모델. `.env`에서 자유롭게 교체 가능

---

## 사전 준비

- gcube 운영서버 워크로드 (HTTPS 지원 필요)
- Telegram 봇 토큰 ([@BotFather](https://t.me/BotFather)에서 발급)

---

## gcube 워크로드 설정

| 항목 | 값 |
|------|---|
| 컨테이너 이미지 | `ollama/ollama:latest` |
| 저장소 유형 | `Docker Hub` |
| 컨테이너 포트 | `8080` |
| 초기명령어 | `bash -c "apt-get update -qq && apt-get install -y nano vim && sleep infinity"` |

> Ollama는 컨테이너 내부에 포함되어 있습니다. Node.js 22 및 OpenClaw는 setup.sh가 자동으로 설치합니다.

---

## 배포 방법

### 1. 레포 클론

```bash
git clone https://github.com/chaeyoon-08/openclaw-ollama.git
cd openclaw-ollama
```

### 2. .env 파일 작성

```bash
cp .env.example .env
```

`.env` 파일을 열어 Telegram 봇 토큰 입력:

```
TELEGRAM_BOT_TOKEN=여기에_토큰_입력
OLLAMA_MODEL=qwen3:8b
OLLAMA_API_KEY=ollama-local
```

### 3. 설정 및 실행

```bash
bash setup.sh
bash run.sh
```

`run.sh` 실행 시 흐름:

1. Ollama 서버 기동
2. 모델 다운로드 (최초 1회, 약 4~5GB)
3. OpenClaw Gateway 실행
4. 터미널에 Gateway Token 출력

### 4. Control UI 접속 및 Telegram 연결

1. gcube 서비스 URL 브라우저 접속
2. Overview 페이지 → **Gateway Token** 입력 → Connect
3. pairing required 메시지가 뜨면 터미널에서:
   ```bash
   openclaw devices list
   openclaw devices approve <requestId>
   ```
4. Telegram 봇에 아무 메시지 전송
5. 봇에서 받은 코드로 터미널에서:
   ```bash
   openclaw pairing approve telegram <코드>
   ```
6. 대화 시작

---

## 모델 변경

`.env`에서 `OLLAMA_MODEL` 값만 바꾸고 `run.sh`를 다시 실행하면 됩니다.

```
OLLAMA_MODEL=qwen3:8b        # 권장 (tool calling 안정적)
# OLLAMA_MODEL=llama3.1:8b   # tool calling 지원
# OLLAMA_MODEL=qwen2.5:7b    # 한국어 품질 우수
```

> ⚠️ **주의:** `deepseek-r1` 계열 모델은 tool calling을 지원하지 않아 OpenClaw와 호환되지 않습니다.

---

## 로그 확인

```bash
# Ollama 로그
cat ~/.openclaw/ollama.log

# Gateway 로그
cat ~/.openclaw/gateway.log

# 실시간 로그
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

---

## 관련 레포

- [openclaw-webui](https://github.com/chaeyoon-08/openclaw-webui) — Gemini/Claude API 버전