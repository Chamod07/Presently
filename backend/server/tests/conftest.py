import pytest
import sys
import os
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

@pytest.fixture
def test_report_id():
    """Return a test report ID for use in tests"""
    return "test_report_123"

@pytest.fixture(autouse=True)
def mock_env_for_tests(monkeypatch):
    """Setup environment variables needed for all tests"""
    monkeypatch.setenv("GEMINI_API_KEY", "test-api-key")
    monkeypatch.setenv("SUPABASE_URL", "https://test-project.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "test-supabase-key")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-secret-key")
    monkeypatch.setenv("ALGORITHM", "HS256")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30")

@pytest.fixture
def sample_grammar_data():
    """Sample grammar analysis response data"""
    return {
        "score": 7.5,
        "weaknesses": [
            {
                "topic": "Run-on sentences",
                "examples": ["This is a very long sentence that keeps going and going and doesn't use proper punctuation."],
                "suggestions": ["Break long sentences into shorter ones.", "Use proper punctuation."]
            },
            {
                "topic": "Passive voice overuse",
                "examples": ["The presentation was given by me.", "The report was completed."],
                "suggestions": ["Use active voice: 'I gave the presentation.'", "Specify who did the action: 'The team completed the report.'"]
            }
        ]
    }
