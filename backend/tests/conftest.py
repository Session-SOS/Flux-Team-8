"""
Shared fixtures for all Flux backend tests.

Uses real OpenAI calls (key loaded from backend/.env).
Mocks Supabase only since DB may not be running.
"""

import os
import pytest
from pathlib import Path
from unittest.mock import MagicMock, patch

from dotenv import load_dotenv
from fastapi.testclient import TestClient

# Load .env from the backend directory so OPENAI_API_KEY is available
_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env")


@pytest.fixture()
def mock_supabase():
    """
    Patch get_supabase_client in goal_service so no real DB calls happen.
    Returns the mock client so tests can configure return values.
    """
    with patch("app.services.goal_service.get_supabase_client") as mock_get_sb:
        mock_sb = MagicMock()
        mock_get_sb.return_value = mock_sb

        # Default: table().insert().execute() returns data with an id
        mock_result = MagicMock()
        mock_result.data = [{"id": "00000000-0000-0000-0000-000000000001"}]

        mock_table = MagicMock()
        mock_table.insert.return_value.execute.return_value = mock_result
        mock_table.update.return_value.eq.return_value.execute.return_value = mock_result
        mock_table.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(data=None)

        mock_sb.table.return_value = mock_table
        yield mock_sb


@pytest.fixture()
def agent():
    """Fresh GoalPlannerAgent instance using real OpenAI from .env."""
    from app.agents.goal_planner import GoalPlannerAgent
    return GoalPlannerAgent(conversation_id="test-conv-1", user_id="test-user-1")


@pytest.fixture()
def client(mock_supabase):
    """FastAPI TestClient with DB mocked out, real OpenAI."""
    from app.main import app
    from app.routers.goals import _active_agents
    _active_agents.clear()
    return TestClient(app)
