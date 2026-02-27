#!/bin/bash
# ============================================================
# OpenClaw Ollama - Setup
# 최초 1회 실행: 설정 파일 자동 생성
# ============================================================
set -e

echo ""
echo "🦞 OpenClaw Ollama Setup"
echo "=============================="
echo ""

# ── .env 파일 확인 ─────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo "❌ .env 파일이 없습니다."
  echo "   cp .env.example .env 후 값을 채워주세요."
  exit 1
fi

# ── .env 로드 ──────────────────────────────────────────────
export $(grep -v '^#' .env | grep -v '^$' | xargs)

# ── 필수 패키지 설치 (packages.txt) ───────────────────────
if [ -f "packages.txt" ]; then
  echo "📦 필수 패키지 설치 중..."
  apt-get update -qq
  xargs apt-get install -y < packages.txt
  echo "✅ 패키지 설치 완료"
fi

# ── Node.js 22 확인 및 설치 ────────────────────────────────
NODE_MAJOR=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
if [ -z "$NODE_MAJOR" ] || [ "$NODE_MAJOR" -lt 22 ]; then
  echo "📦 Node.js 22 설치 중..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
  echo "✅ Node.js 설치 완료: $(node --version)"
else
  echo "✅ Node.js 감지됨: $(node --version)"
fi

# ── Telegram 토큰 확인 ─────────────────────────────────────
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "❌ TELEGRAM_BOT_TOKEN이 설정되지 않았습니다."
  exit 1
fi
echo "📱 Telegram 봇 토큰 감지됨"

# ── Ollama 모델 설정 ───────────────────────────────────────
OLLAMA_MODEL="${OLLAMA_MODEL:-deepseek-r1:7b}"
OLLAMA_BASE_URL="http://localhost:11434"
OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama-local}"
echo "🤖 사용 모델: ${OLLAMA_MODEL}"

# ── Ollama 설치 확인 ───────────────────────────────────────
if command -v ollama &> /dev/null; then
  echo "✅ Ollama 감지됨: $(ollama --version)"
else
  echo "📦 Ollama 설치 중..."
  curl -fsSL https://ollama.com/install.sh | sh
  echo "✅ Ollama 설치 완료"
fi

# ── openclaw 실행 경로 확인 ────────────────────────────────
if command -v openclaw &> /dev/null; then
  OPENCLAW_CMD="openclaw"
  echo "✅ OpenClaw 감지됨: $(openclaw --version)"
elif [ -f "/app/openclaw.mjs" ]; then
  OPENCLAW_CMD="node /app/openclaw.mjs"
  echo "✅ OpenClaw 감지됨 (공식 이미지): $(node /app/openclaw.mjs --version)"
else
  echo "📦 OpenClaw 설치 중..."
  npm install -g openclaw@latest
  OPENCLAW_CMD="openclaw"
fi

# ── 설정 디렉토리 생성 ─────────────────────────────────────
CONFIG_DIR="$HOME/.openclaw"
AGENT_DIR="$CONFIG_DIR/agents/main/agent"
SESSION_DIR="$CONFIG_DIR/agents/main/sessions"
mkdir -p "$CONFIG_DIR" "$AGENT_DIR" "$SESSION_DIR"

# ── 게이트웨이 토큰 생성 ───────────────────────────────────
GATEWAY_TOKEN=$(openssl rand -hex 24 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-')

# ── openclaw.json 생성 ─────────────────────────────────────
echo "⚙️  openclaw.json 생성 중..."
cat > "$CONFIG_DIR/openclaw.json" << JSONEOF
{
  "meta": {
    "lastTouchedVersion": "2026.2.23"
  },
  "agents": {
    "defaults": {
      "model": "ollama/${OLLAMA_MODEL}",
      "memorySearch": {
        "enabled": false
      }
    }
  },
  "gateway": {
    "port": 8080,
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    },
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
JSONEOF
echo "✅ openclaw.json 생성 완료"

# ── auth-profiles.json 생성 ────────────────────────────────
cat > "$AGENT_DIR/auth-profiles.json" << JSONEOF
{
  "version": 1,
  "profiles": {
    "ollama:default": {
      "type": "api_key",
      "provider": "ollama",
      "baseUrl": "${OLLAMA_BASE_URL}",
      "key": "${OLLAMA_API_KEY}"
    }
  },
  "usageStats": {}
}
JSONEOF
echo "✅ auth-profiles.json 생성 완료"

# ── .env 복사 ──────────────────────────────────────────────
cp .env "$CONFIG_DIR/.env"
echo "✅ .env 복사 완료"

echo ""
echo "✅ 설정 완료!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶  다음 단계: bash run.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"