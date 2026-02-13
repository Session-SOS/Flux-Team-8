#!/usr/bin/env bash
# ============================================================
# Flux — Development Environment Setup (macOS / Linux)
# Installs frontend and backend dependencies, copies .env files,
# and validates that required tools are present.
# Usage:  bash scripts/setup.sh
# ============================================================

set -e  # Exit immediately on any error

# ---------- Colored output helpers ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Resolve project root ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo ""
echo "=============================="
echo "  Flux — Project Setup"
echo "=============================="
echo ""

# ---------- 1. Check Node.js >= 18 ----------
if ! command -v node &> /dev/null; then
  error "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org"
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  error "Node.js 18+ is required (found v$(node -v)). Please upgrade."
fi
info "Node.js $(node -v) detected"

# ---------- 2. Check Python >= 3.11 ----------
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
  PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
  PYTHON_CMD="python"
else
  error "Python is not installed. Please install Python 3.11+ from https://python.org"
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]; }; then
  error "Python 3.11+ is required (found $PYTHON_VERSION). Please upgrade."
fi
info "Python $PYTHON_VERSION detected"

# ---------- 3. Check Docker ----------
if ! command -v docker &> /dev/null; then
  error "Docker is not installed. Please install Docker Desktop from https://docs.docker.com/desktop/install/mac-install/"
fi

if ! docker info &> /dev/null 2>&1; then
  error "Docker Desktop is not running. Please start Docker Desktop and try again."
fi
info "Docker $(docker --version | awk '{print $3}' | tr -d ',') detected and running"

# ---------- 4. Check Supabase CLI ----------
if ! command -v supabase &> /dev/null; then
  echo ""
  echo "--- Installing Supabase CLI ---"
  if command -v brew &> /dev/null; then
    brew install supabase/tap/supabase
    info "Supabase CLI installed via Homebrew"
  else
    error "Supabase CLI is not installed and Homebrew is not available. Install manually: https://supabase.com/docs/guides/local-development/cli/getting-started"
  fi
else
  info "Supabase CLI $(supabase --version 2>/dev/null) detected"
fi

# ---------- 5. Start Supabase locally ----------
echo ""
echo "--- Supabase Local Setup ---"

if supabase status &> /dev/null 2>&1; then
  info "Supabase is already running"
else
  echo "Starting Supabase (first run downloads ~2-3 GB of Docker images)..."
  supabase start
  info "Supabase local development stack started"
fi

echo ""
echo "Supabase local URLs and keys:"
supabase status
echo ""

# ---------- 6. Frontend setup ----------
echo ""
echo "--- Frontend Setup ---"

cd "$PROJECT_ROOT/frontend"
npm install
info "Frontend dependencies installed"

if [ ! -f .env ]; then
  cp .env.example .env
  info "Created frontend/.env from .env.example"
else
  warn "frontend/.env already exists — skipping copy"
fi

# ---------- 7. Backend setup ----------
echo ""
echo "--- Backend Setup ---"

cd "$PROJECT_ROOT/backend"

if [ ! -f requirements.txt ]; then
  warn "backend/requirements.txt not found — skipping Python dependency install"
else
  $PYTHON_CMD -m venv venv
  # Activate venv (POSIX-compatible)
  source venv/bin/activate
  pip install --upgrade pip --quiet
  pip install -r requirements.txt
  info "Backend dependencies installed in venv"
fi

if [ ! -f .env ]; then
  cp .env.example .env
  info "Created backend/.env from .env.example"
else
  warn "backend/.env already exists — skipping copy"
fi

# ---------- 8. Done ----------
cd "$PROJECT_ROOT"

echo ""
echo "=============================="
echo -e "  ${GREEN}Setup complete!${NC}"
echo "=============================="
echo ""
echo "Next steps:"
echo "  1. Fill in API keys in backend/.env"
echo "  2. Supabase Studio:  http://127.0.0.1:54323"
echo "  3. Start frontend:   cd frontend && npm run dev"
echo "  4. Start backend:    cd backend && source venv/bin/activate && make dev"
echo "  5. Open http://localhost:5173 in your browser"
echo ""
echo "Useful Supabase commands:"
echo "  supabase status   — Show local URLs and keys"
echo "  supabase stop     — Stop all Supabase containers"
echo "  supabase db reset — Reset database to clean state"
echo ""
