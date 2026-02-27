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
[DeepSeek-R1:7b (로컬 모델)]
```

- **OpenClaw** — 메시징 채널과 LLM을 연결하는 게이트웨이
- **Ollama** — 로컬 LLM 실행 프레임워크. API 키 없이 무료로 사용 가능
- **DeepSeek-R1:7b** — 기본 모델. `.env`에서 자유롭게 교체 가능

---

## 사전 준비

- gcube 운영서버 워크로드 (HTTPS 지원 필요)
- Telegram 봇 토큰 ([@BotFather](https://t.me/BotFather)에서 발급)

---

## gcube 워크로드 설정

| 항목 | 값 |
|------|---|
| 컨테이너 이미지 | `ghcr.io/openclaw/openclaw:latest` |
| 컨테이너 포트 | `8080` |
| 초기명령어 | `bash -c "sleep infinity"` |

> Ollama는 컨테이너 내부에서 설치됩니다.

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
OLLAMA_MODEL=deepseek-r1:7b
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
OLLAMA_MODEL=llama3.2:8b
# OLLAMA_MODEL=qwen2.5:7b
# OLLAMA_MODEL=phi4:3b
```

---

## 로그 확인

```bash
# Ollama 로그
cat ~/.openclaw/ollama.log

# Gateway 로그
cat ~/.openclaw/gateway.log
```

---

## 관련 레포

- [openclaw-webui](https://github.com/chaeyoon-08/openclaw-webui) — Gemini/Claude API 버전