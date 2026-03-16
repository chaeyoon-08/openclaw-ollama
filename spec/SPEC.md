# 기술 명세: OpenClaw Telegram AI Agent Gateway (Ollama)

> 참조: [spec/PRD.md](./PRD.md)

---

## 1. 디렉토리 구조

### Repo 구조

```
openclaw-ollama/
├── setup.sh               ← 최초 1회: 패키지 설치 + 설정 파일 생성 + workspace 구성
├── run.sh                 ← Ollama 기동 + 게이트웨이 실행 + 페어링 안내
├── .env.example           ← TELEGRAM_BOT_TOKEN + OLLAMA_MODEL + OLLAMA_API_KEY 템플릿
├── .env                   ← 실제 키 (gitignore)
├── .gitignore
├── packages.txt           ← 시스템 의존 패키지 목록 (apt-get 설치용)
├── README.md              ← Ollama 기반 Telegram 배포 가이드
├── CLAUDE.md              ← Claude Code 프로젝트 가이드라인
├── identity/              ← 에이전트 Bootstrap 파일
│   ├── AGENTS.md          ← 에이전트 지시사항 (한국어 답변)
│   └── IDENTITY.md        ← 에이전트 정체성 (DA Assistant)
├── docs/                  ← Knowledge Base 문서
│   └── test_report.md     ← 테스트용 문서
└── spec/
    ├── PRD.md             ← 제품 요구사항
    └── SPEC.md            ← 기술 명세 (이 파일)
```

### 런타임 생성 디렉토리 (`~/.openclaw/`)

`setup.sh`가 생성하며 repo에는 포함되지 않는다.

```
~/.openclaw/
├── openclaw.json                      ← 게이트웨이 + 채널 설정
├── .env                               ← 환경변수 백업 (repo .env 복사본)
├── ollama.log                         ← Ollama 서버 로그 (run.sh 실행 시)
├── gateway.log                        ← 게이트웨이 로그 (run.sh 실행 시)
├── workspace/                         ← 에이전트 작업 공간
│   ├── AGENTS.md                      ← identity/AGENTS.md에서 복사됨
│   ├── IDENTITY.md                    ← identity/IDENTITY.md에서 복사됨
│   └── test_report.md                 ← docs/test_report.md에서 복사됨
└── agents/main/
    ├── agent/
    │   └── auth-profiles.json         ← Ollama API 연결 정보
    └── sessions/
```

---

## 2. 파일별 명세

### 2-1. `.env.example`

**파일 내용** (전문):

```env
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
OLLAMA_MODEL=qwen3:32b
OLLAMA_API_KEY=ollama-local
```

- 정확히 3줄, 빈 줄 없음
- `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` 포함 금지

---

### 2-2. `packages.txt`

**파일 내용** (전문):

```
curl
git
zstd
python3
```

- `apt-get install`에 전달되는 패키지 목록
- `setup.sh`에서 `xargs apt-get install -y < packages.txt` 로 설치

---

### 2-3. `setup.sh`

**역할**: 최초 1회 실행. 시스템 패키지, Node.js, Ollama, OpenClaw를 설치하고, `.env`를 읽어 `~/.openclaw/` 아래 설정 파일을 생성하며, `identity/`, `docs/` 파일을 workspace에 복사한다.

**실행 조건**: `set -e` (오류 시 즉시 종료)

#### 실행 흐름

| 순서 | 동작 | 행 번호 |
|------|------|---------|
| 1 | .env 파일 존재 확인 | 14-18 |
| 2 | .env 로드 (export) | 21 |
| 3 | `packages.txt` 시스템 패키지 설치 | 24-29 |
| 4 | Node.js 22 확인 및 설치 | 32-40 |
| 5 | `TELEGRAM_BOT_TOKEN` 검증 | 43-46 |
| 6 | Ollama 모델/URL/API키 변수 설정 | 50-52 |
| 7 | Ollama 설치 확인/실행 | 56-62 |
| 8 | openclaw NPM 패키지 설치 확인 | 65-75 |
| 9 | 설정 디렉토리 생성 (`~/.openclaw/`, `agents/main/agent/`, `sessions/`) | 78-81 |
| 10 | 게이트웨이 토큰 자동 생성 (openssl rand) | 84 |
| 11 | `openclaw.json` 생성 | 88-129 |
| 12 | `auth-profiles.json` 생성 | 133-146 |
| 13 | `.env` → `~/.openclaw/.env` 복사 | 150 |
| 14 | workspace 디렉토리 생성 | 161-162 |
| 15 | `identity/*.md` → workspace 복사 | 165-169 |
| 16 | `docs/*.md` → workspace 복사 | 172-176 |

#### 고정 값

| 항목 | 값 | 비고 |
|------|-----|------|
| Ollama 기본 모델 | `deepseek-r1:7b` (폴백) | `.env`의 `OLLAMA_MODEL`이 우선 |
| Ollama 서버 URL | `http://localhost:11434` | 로컬 고정 |
| Ollama API 키 | `ollama-local` (폴백) | `.env`의 `OLLAMA_API_KEY`가 우선 |
| 게이트웨이 포트 | `8080` | gcube 워크로드 포트와 일치 |
| 게이트웨이 모드 | `local` | |
| 게이트웨이 바인드 | `lan` | |
| 인증 모드 | `token` | |
| Telegram DM 정책 | `pairing` | |
| Telegram 스트리밍 | `off` | |
| auth-profiles 프로필 키 | `ollama:default` | |
| auth-profiles provider | `ollama` | |

---

### 2-4. `run.sh`

**역할**: `~/.openclaw/openclaw.json` 검증 → Ollama 서버 기동 → 모델 다운로드 → 게이트웨이 백그라운드 실행 → Gateway Token + Telegram 페어링 안내 출력.

**실행 조건**: `set -e`

#### 실행 흐름

| 순서 | 동작 | 행 번호 |
|------|------|---------|
| 1 | `openclaw.json` 존재 확인 | 11-14 |
| 2 | `.env` 로드 (있으면) | 17-19 |
| 3 | Ollama 모델 변수 설정 | 21 |
| 4 | openclaw 실행 경로 확인 | 24-31 |
| 5 | 게이트웨이 토큰 추출 (python3) | 34 |
| 6 | 기존 openclaw/ollama 프로세스 종료 | 42-46 |
| 7 | Ollama 서버 백그라운드 기동 | 49-51 |
| 8 | Ollama 준비 대기 (최대 30초 폴링) | 54-66 |
| 9 | `ollama pull ${OLLAMA_MODEL}` 모델 다운로드 | 69-72 |
| 10 | `openclaw gateway --port 8080` 백그라운드 실행 | 75-78 |
| 11 | 프로세스 생존 확인 | 81-85 |
| 12 | Gateway Token + 페어링 안내 메시지 출력 | 87-118 |

#### 출력 메시지 구조

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 모델: ${OLLAMA_MODEL}
🌐 gcube URL로 접속 후 Overview 페이지에서:
   Gateway Token 필드에 아래 토큰 입력 후 Connect

🔑 토큰: ${TOKEN}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 다음 단계:
  1) Telegram 봇에 아무 메시지 보내기 → Pairing 코드 수신
  2) Device 승인: openclaw devices list → openclaw devices approve <requestId>
  3) Pairing 승인: openclaw pairing approve telegram <코드>
  4) 대화 시작

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [종료]  pkill -9 -f 'openclaw'; pkill -9 -f 'ollama'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 2-5. `identity/AGENTS.md`

**역할**: 에이전트 운영 지시사항. OpenClaw bootstrap 파일로 자동 컨텍스트 주입됨.

**핵심 지시사항**:
- 모든 응답을 한국어로 작성
- 기술 용어는 영어 유지 가능
- workspace 문서를 참조하여 답변
- 간결하고 전문적인 톤

**복사 경로**: `setup.sh` 실행 시 → `~/.openclaw/workspace/AGENTS.md`

---

### 2-6. `identity/IDENTITY.md`

**역할**: 에이전트 정체성 정의. OpenClaw bootstrap 파일로 자동 컨텍스트 주입됨.

**정체성 정의**:

| 항목 | 값 |
|------|-----|
| 이름 | DA Assistant |
| 역할 | 문서 생성, 편집, 분석 담당 어시스턴트 |
| 사용자 호칭 | 담당자님 |
| 톤 | 사무적이고 간결하게 |
| 제약사항 | 불필요한 감탄사, 이모지 사용 금지 |
| 자기소개 | "저는 DA Assistant입니다. 문서 생성, 편집, 분석을 담당합니다." |

**복사 경로**: `setup.sh` 실행 시 → `~/.openclaw/workspace/IDENTITY.md`

---

### 2-7. `docs/` 디렉토리

**역할**: Knowledge Base 문서 저장소. `setup.sh` 실행 시 `~/.openclaw/workspace/`로 자동 복사.

**현재 포함 문서**:

| 파일 | 내용 | 용도 |
|------|------|------|
| `test_report.md` | 클라우드 GPU 인프라 시장 분석 보고서 | 문서 기반 Q&A 검증용 |

**검증 질문 예시**:
- "보고서 작성 날짜는?" → 기대 응답: "2026년 3월 5일"
- "글로벌 클라우드 GPU 시장 규모는?" → 기대 응답: "2025년 기준 약 847억 달러"

**확장 방법**: `docs/` 폴더에 `.md` 파일 추가 후 `bash setup.sh` 재실행.

---

## 3. openclaw.json 설정 명세

`setup.sh`가 생성하는 `~/.openclaw/openclaw.json`의 최종 형태.

```jsonc
{
  // openclaw 내부 버전 트래킹
  "meta": {
    "lastTouchedVersion": "2026.2.23"
  },

  // 에이전트 기본 설정
  "agents": {
    "defaults": {
      "model": "ollama/${OLLAMA_MODEL}",    // .env에서 읽은 모델 (예: ollama/qwen3:32b)
      "memorySearch": {
        "enabled": false                     // 메모리 검색 비활성화
      }
    }
  },

  // 게이트웨이 서버 설정
  "gateway": {
    "port": 8080,              // gcube 워크로드 포트와 일치 필수
    "mode": "local",           // 로컬 모드
    "bind": "lan",             // LAN 바인딩 (컨테이너 내부)
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    },
    "auth": {
      "mode": "token",         // 토큰 기반 인증
      "token": "<auto-generated>"
    }
  },

  // 채널 설정 — Telegram만 활성화
  "channels": {
    "telegram": {
      "enabled": true,
      "streaming": "off",      // 스트리밍 비활성화
      "botToken": "<TELEGRAM_BOT_TOKEN>",
      "dmPolicy": "pairing"    // DM 시 페어링 코드 발급
    }
  },

  // 플러그인 — Telegram만 활성화
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
```

---

## 4. auth-profiles.json 설정 명세

`setup.sh`가 생성하는 `~/.openclaw/agents/main/agent/auth-profiles.json`.

```json
{
  "version": 1,
  "profiles": {
    "ollama:default": {
      "type": "api_key",
      "provider": "ollama",
      "baseUrl": "http://localhost:11434",
      "key": "<OLLAMA_API_KEY>"
    }
  },
  "usageStats": {}
}
```

- `anthropic:default` 프로필 없음 (외부 API 미사용)
- `baseUrl`은 Ollama 로컬 서버 주소 (`http://localhost:11434` 고정)

---

## 5. Workspace Bootstrap 시스템

### 5-1. 개요

OpenClaw는 `openclaw.json`에 시스템 프롬프트 필드를 직접 제공하지 않는다. 대신 **workspace bootstrap 파일**을 에이전트 컨텍스트에 자동 주입한다.

| Bootstrap 파일 | 용도 | 이 프로젝트의 사용 여부 |
|---------------|------|----------------------|
| `AGENTS.md` | 에이전트 운영 지시사항 | **사용** (한국어 답변 설정) |
| `IDENTITY.md` | 에이전트 정체성 | **사용** (DA Assistant) |
| `SOUL.md` | 에이전트 성격/톤 | 미사용 |
| `USER.md` | 사용자 정보 | 미사용 |
| `TOOLS.md` | 도구 문서 | 미사용 |

### 5-2. 파일 관리 방식

**repo에서 관리** → **setup.sh가 workspace로 복사** → **에이전트가 자동 로드**

```
identity/AGENTS.md     ─┐
identity/IDENTITY.md   ─┤  bash setup.sh   ┌──→ 에이전트 컨텍스트에 주입
                        ├─────────────────→ ~/.openclaw/workspace/
docs/test_report.md    ─┤                  └──→ 에이전트가 참조 가능
docs/*.md              ─┘
```

- identity/ 파일은 에이전트 동작 규칙을 정의 (bootstrap으로 자동 주입)
- docs/ 파일은 참조 문서 (에이전트가 필요 시 읽음)
- 수정 시: 파일 편집 → `bash setup.sh` 재실행 → 게이트웨이 재시작

### 5-3. 검증 방법

| 검증 항목 | 명령어 | 기대 결과 |
|----------|--------|----------|
| workspace 생성 | `ls ~/.openclaw/workspace/` | AGENTS.md, IDENTITY.md, test_report.md |
| AGENTS.md 내용 | `cat ~/.openclaw/workspace/AGENTS.md` | 한국어 답변 지시 포함 |
| IDENTITY.md 내용 | `cat ~/.openclaw/workspace/IDENTITY.md` | DA Assistant 정체성 포함 |
| 한국어 응답 | Telegram에서 영어로 질문 | 한국어 답변 |
| 자기소개 | "자기소개해줘" | "DA Assistant...문서 생성, 편집, 분석..." |

---

## 6. .gitignore 정책

```gitignore
# 환경변수 (API 키 노출 방지)
.env
~/.openclaw/.env

# OpenClaw 설정 및 데이터
.openclaw/

# 로그
*.log

# OS
.DS_Store
Thumbs.db

# Claude Code 로컬 설정
# .claude/
# spec/
# CLAUDE.md

# 에디터
.vscode/
.idea/
*.swp
```

**주의**: `spec/`, `CLAUDE.md`, `.claude/`는 gitignore 주석 처리 상태이다. 필요 시 주석 해제하여 배포 repo에서 제외할 수 있다.

---

## 7. 변경 요약 매트릭스

| 파일/디렉토리 | 유형 | 역할 |
|-------------|------|------|
| `.env.example` | 설정 템플릿 | `TELEGRAM_BOT_TOKEN`, `OLLAMA_MODEL`, `OLLAMA_API_KEY` |
| `packages.txt` | 패키지 목록 | 시스템 의존 패키지 (curl, git, zstd, python3) |
| `setup.sh` | 셸 스크립트 | 패키지/Node.js/Ollama/openclaw 설치, 설정 파일 생성, identity/docs 복사 |
| `run.sh` | 셸 스크립트 | Ollama 기동, 모델 로드, 게이트웨이 실행, 페어링 안내 |
| `identity/AGENTS.md` | Bootstrap | 한국어 답변 지시 |
| `identity/IDENTITY.md` | Bootstrap | DA Assistant 정체성 |
| `docs/test_report.md` | Knowledge Base | 문서 Q&A 검증용 |
| `README.md` | 문서 | Ollama 기반 Telegram 배포 가이드 |
