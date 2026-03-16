spec/SPEC.md를 읽고, 변경 명세대로 아래 파일들을 실제로 수정하라.

## 수정 대상 파일

1. `.env.example`
2. `packages.txt`
3. `setup.sh`
4. `run.sh`
5. `identity/AGENTS.md`
6. `identity/IDENTITY.md`

## 작업 순서

### 1단계: 명세 확인
spec/SPEC.md의 파일별 명세 섹션을 읽고, 각 파일의 현재 상태와 기대 상태를 파악한다.

### 2단계: 파일 수정

**`.env.example`**
- `TELEGRAM_BOT_TOKEN`, `OLLAMA_MODEL`, `OLLAMA_API_KEY` 세 줄만 존재해야 함
- `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`는 어떤 형태로도 포함 금지

**`packages.txt`**
- `curl`, `git`, `zstd`, `python3` 패키지 목록
- `setup.sh`에서 `xargs apt-get install -y < packages.txt`로 사용됨

**`setup.sh`**
- 시스템 패키지: `packages.txt` 기반 설치
- Node.js 22: 확인 및 설치
- Ollama: 설치 확인/실행
- API 키 검증: `TELEGRAM_BOT_TOKEN` 단독 검증 (외부 API 키 불필요)
- 모델: `ollama/${OLLAMA_MODEL}` 형식으로 `openclaw.json`에 삽입
- `auth-profiles.json`: `ollama:default` 프로필, provider `ollama`, baseUrl `http://localhost:11434`
- workspace: `identity/*.md`와 `docs/*.md`를 `~/.openclaw/workspace/`에 복사
- 외부 API 관련 변수(`ANTHROPIC_API_KEY`, `GEMINI_API_KEY`) 없음

**`run.sh`**
- Ollama 서버 기동 (nohup, :11434)
- Ollama 준비 대기 (최대 30초 폴링)
- `ollama pull ${OLLAMA_MODEL}` 모델 다운로드
- `openclaw gateway --port 8080` 백그라운드 실행
- Gateway Token + Telegram 페어링 안내 출력
- 프로세스 종료 안내에 ollama 포함

**`identity/AGENTS.md`**
- 한국어 답변 지시사항 포함
- 간결하고 전문적인 톤 지시

**`identity/IDENTITY.md`**
- DA Assistant 정체성 정의
- 사용자 호칭: 담당자님
- 톤: 사무적이고 간결하게, 이모지 없이

### 3단계: 검증
수정 완료 후 각 파일에서 아래 항목이 없는지 확인한다.

| 항목 | 파일 |
|------|------|
| `ANTHROPIC_API_KEY` | `.env.example`, `setup.sh` |
| `GEMINI_API_KEY` | `.env.example`, `setup.sh` |
| `google/gemini` | `setup.sh` |
| `anthropic/claude` | `setup.sh` |
| `anthropic:default` | `setup.sh` |

문제가 있으면 즉시 수정한다.

## 완료 기준
- `.env.example`: `TELEGRAM_BOT_TOKEN`, `OLLAMA_MODEL`, `OLLAMA_API_KEY` 세 줄만 존재
- `packages.txt`: curl, git, zstd, python3
- `setup.sh`: 외부 API 분기 없음, Ollama 전용 설정, identity/docs 복사 로직 존재
- `run.sh`: Ollama 서버 기동 + Gateway 실행, 페어링 안내 출력
- `identity/AGENTS.md`: 한국어 답변 지시 포함
- `identity/IDENTITY.md`: DA Assistant 정체성 정의 포함
