spec/PRD.md와 spec/SPEC.md를 읽고, README.md를 Ollama 기반 Telegram 배포 가이드로 재작성하라.

## 작업 순서

### 1단계: 명세 읽기
- spec/PRD.md: 프로젝트 개요, 목표, 기술 스택, 배포 흐름 확인
- spec/SPEC.md: 파일별 명세, workspace bootstrap 시스템 확인

### 2단계: 현재 README.md 읽기
기존 내용을 파악하여 유지할 섹션과 제거할 섹션을 구분한다.

### 3단계: README.md 재작성

아래 구조로 작성한다.

---

**포함할 섹션 (순서대로)**

1. **제목 및 한 줄 소개**
   - Telegram 봇 + Ollama 로컬 LLM 게이트웨이임을 명시
   - API 비용 없이 로컬 모델로 운영 가능함을 강조

2. **전체 흐름**
   - mermaid 플로우차트: Ollama 설치 + Telegram 전용 흐름 표현

3. **gcube 워크로드 설정**
   - 이미지: `ollama/ollama:latest`
   - 포트: `8080`
   - 초기명령어: `bash -c "apt-get update -qq && apt-get install -y nano vim && sleep infinity"`

4. **사전 준비**
   - Telegram 봇 토큰 발급 방법 (BotFather, `/newbot`)
   - Anthropic/Gemini API 키 발급 불필요 명시

5. **실행 방법** (5단계)
   1. `git clone` → `cd openclaw-ollama`
   2. `cp .env.example .env` → `nano .env` (TELEGRAM_BOT_TOKEN, OLLAMA_MODEL 입력)
   3. `bash setup.sh` (패키지/Node.js/Ollama/openclaw 설치, 설정 생성, 문서 복사)
   4. `bash run.sh` (Ollama 기동 → 모델 다운로드 → Gateway 실행)
   5. Telegram 봇에 메시지 전송 → 페어링 코드 수신 → `openclaw pairing approve telegram [코드]`

6. **Knowledge Base 문서**
   - `docs/` 폴더의 .md 파일이 `~/.openclaw/workspace/`에 자동 복사됨
   - `identity/` 폴더의 bootstrap 파일도 자동 복사 (AGENTS.md, IDENTITY.md)

7. **테스트 성공 기준**
   - Telegram 봇에 메시지 전송 → 로컬 LLM 한국어 텍스트 응답 수신
   - 문서 기반 Q&A 검증

8. **파일 구조**
   - repo 파일 목록 (identity/, docs/, packages.txt 포함)
   - 런타임 생성 디렉토리 (~/.openclaw/, ollama.log 포함)

9. **모델 변경**
   - `.env`의 `OLLAMA_MODEL` 변경 방법
   - 권장/호환 모델 목록
   - deepseek-r1 비호환 경고

10. **문제 해결**
    - Gateway 실행 실패: `cat ~/.openclaw/gateway.log`
    - Ollama 서버 미응답: `cat ~/.openclaw/ollama.log`
    - 프로세스 정리 및 재시작 (openclaw + ollama)
    - Telegram 봇 미응답: 페어링 재시도
    - 문서 미복사: setup.sh 재실행

11. **주요 명령어**
    - 자주 사용하는 openclaw + ollama 명령어 모음

12. **기술 스택**
    - Ollama 로컬 LLM, Node.js 22, Telegram Bot API, gcube 컨테이너

---

**제거할 섹션 (포함 금지)**

- Anthropic API 키 발급 안내
- Gemini API 키 발급 안내
- 외부 API 관련 기술 스택

---

**작성 원칙**

- 한국어로 작성한다.
- 코드 블록을 활용하여 명령어를 명확히 표시한다.
- 불필요한 내용 없이 간결하게 작성한다.
- mermaid 플로우차트를 포함할 경우 Ollama 설치 + Telegram 전용 흐름만 표현한다.

### 4단계: 완료 확인

작성 후 README.md에서 아래 문자열이 없는지 확인한다.
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `console.anthropic.com`
- `aistudio.google.com`
- `anthropic/claude`
- `google/gemini`

존재하면 즉시 해당 부분을 수정한다.
