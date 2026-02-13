# ============================================================
# Flux Backend — Makefile
# Common development commands for the FastAPI backend.
# Usage:  make <target>
# ============================================================

.PHONY: install dev test lint format migrate

# Install Python dependencies from requirements.txt
install:
	pip install -r requirements.txt

# Start the FastAPI dev server with auto-reload
dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run the test suite with verbose output
test:
	pytest tests/ -v

# Check code formatting and lint rules (non-destructive)
lint:
	black app/ --check
	ruff check app/

# Auto-fix formatting and lint issues
format:
	black app/
	ruff check app/ --fix

# Apply database migrations via Alembic
migrate:
	alembic upgrade head
