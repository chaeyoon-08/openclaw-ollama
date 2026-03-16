spec/SPEC.md의 명세와 현재 파일 상태를 비교하여 검증 리포트를 출력하라.

## 검증 대상 파일

- `.env.example`
- `packages.txt`
- `setup.sh`
- `run.sh`
- `identity/AGENTS.md`
- `identity/IDENTITY.md`

## 검증 절차

### 1단계: 파일 읽기
spec/SPEC.md와 검증 대상 파일들을 모두 읽는다.

### 2단계: 항목별 검증

각 항목을 검사하여 PASS / FAIL 로 판정한다.

**`.env.example` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| E1 | `ANTHROPIC_API_KEY` 문자열 없음 | 없어야 함 |
| E2 | `GEMINI_API_KEY` 문자열 없음 | 없어야 함 |
| E3 | `TELEGRAM_BOT_TOKEN` 존재 | 있어야 함 |
| E4 | `OLLAMA_MODEL` 존재 | 있어야 함 |
| E5 | `OLLAMA_API_KEY` 존재 | 있어야 함 |
| E6 | 총 줄 수 (빈 줄 제외) | 3줄 |

**`packages.txt` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| P1 | `curl` 존재 | 있어야 함 |
| P2 | `git` 존재 | 있어야 함 |
| P3 | `python3` 존재 | 있어야 함 |

**`setup.sh` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| S1 | `ANTHROPIC_API_KEY` 참조 없음 | 없어야 함 |
| S2 | `GEMINI_API_KEY` 참조 없음 | 없어야 함 |
| S3 | `google/gemini` 문자열 없음 | 없어야 함 |
| S4 | `anthropic/claude` 문자열 없음 | 없어야 함 |
| S5 | `TELEGRAM_BOT_TOKEN` 검증 로직 존재 | 있어야 함 |
| S6 | `ollama/${OLLAMA_MODEL}` 모델 형식 존재 | 있어야 함 |
| S7 | `auth-profiles.json`에 `ollama:default` 키 사용 | 있어야 함 |
| S8 | `"provider": "ollama"` 존재 | 있어야 함 |
| S9 | `"baseUrl"` 에 `localhost:11434` 존재 | 있어야 함 |
| S10 | `identity/*.md` 복사 로직 존재 | 있어야 함 |
| S11 | `docs/*.md` 복사 로직 존재 | 있어야 함 |
| S12 | `packages.txt` 참조 존재 | 있어야 함 |
| S13 | Node.js 22 설치 로직 존재 | 있어야 함 |
| S14 | Ollama 설치 로직 존재 | 있어야 함 |

**`run.sh` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| R1 | `ollama serve` 서버 기동 존재 | 있어야 함 |
| R2 | `ollama pull` 모델 다운로드 존재 | 있어야 함 |
| R3 | `openclaw gateway --port 8080` 실행 존재 | 있어야 함 |
| R4 | `openclaw pairing approve telegram` 안내 존재 | 있어야 함 |
| R5 | Ollama 준비 대기 로직 존재 (localhost:11434 폴링) | 있어야 함 |
| R6 | 프로세스 종료 안내에 `ollama` 포함 | 있어야 함 |

**`identity/AGENTS.md` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| A1 | 한국어(Korean) 응답 지시 존재 | 있어야 함 |
| A2 | `한국어` 문자열 존재 | 있어야 함 |

**`identity/IDENTITY.md` 검증**

| # | 검증 항목 | 기대값 |
|---|----------|--------|
| I1 | `DA Assistant` 이름 존재 | 있어야 함 |
| I2 | `담당자님` 호칭 존재 | 있어야 함 |
| I3 | 자기소개 문장 존재 | 있어야 함 |

### 3단계: 리포트 출력

아래 형식으로 출력한다.

```
=== 검증 리포트 ===

[.env.example]
  E1 PASS  ANTHROPIC_API_KEY 없음
  E2 PASS  GEMINI_API_KEY 없음
  ...

[packages.txt]
  P1 PASS  curl 존재
  ...

[setup.sh]
  S1 PASS  ANTHROPIC_API_KEY 없음
  ...

[run.sh]
  R1 PASS  ollama serve 존재
  ...

[identity/AGENTS.md]
  A1 PASS  한국어 응답 지시 존재
  ...

[identity/IDENTITY.md]
  I1 PASS  DA Assistant 이름 존재
  ...

=== 결과 요약 ===
전체: N개 항목
통과: N개
실패: N개

실패 항목:
  - [파일명] 항목번호: 설명
```

### 4단계: 실패 항목 처리

FAIL 항목이 있을 경우:
- 어떤 변경이 필요한지 구체적으로 설명한다.
- 사용자에게 `/implement` 커맨드로 수정할 것을 제안한다.

FAIL 항목이 없을 경우:
- "모든 항목 통과. SPEC.md 명세와 일치합니다." 출력
