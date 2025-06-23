import pytest
from fastapi.testclient import TestClient
from fastapi import status
from unittest.mock import patch, MagicMock
import json

from main import app
from controllers.grammar_analysis_controller import analyzer

client = TestClient(app)

@pytest.fixture
def mock_auth():
    with patch("controllers.grammar_analysis_controller.get_current_user_id", return_value="test-user-id"):
        yield

@pytest.fixture
def mock_grammar_analyzer():
    with patch.object(analyzer, "analyze_grammar") as mock:
        mock.return_value = {
            "score": 8,
            "weaknesses": [
                {
                    "topic": "Sentence fragments",
                    "examples": ["Without proper structure."],
                    "suggestions": ["Complete the sentence with a subject and verb."]
                }
            ]
        }
        yield mock

@pytest.fixture
def mock_storage():
    with patch("controllers.grammar_analysis_controller.storage_service") as mock:
        mock_execute = MagicMock()
        mock_eq = MagicMock()
        mock_eq.execute = MagicMock(return_value=mock_execute)
        mock_select = MagicMock()
        mock_select.eq = MagicMock(return_value=mock_eq)
        mock_update = MagicMock()
        mock_update.eq = MagicMock(return_value=mock_eq)
        
        mock_table = MagicMock()
        mock_table.select = MagicMock(return_value=mock_select)
        mock_table.update = MagicMock(return_value=mock_update)
        
        mock.supabase.table = MagicMock(return_value=mock_table)
        
        mock_execute.data = [
            {
                "scoreGrammar": 8,
                "subScoresGrammar": {
                    "grammar": 8,
                    "structure": 7,
                    "wordChoice": 9
                },
                "weaknessTopicsGrammar": [
                    {
                        "topic": "Sentence fragments",
                        "examples": ["Without proper structure."],
                        "suggestions": ["Complete the sentence with a subject and verb."]
                    }
                ]
            }
        ]
        
        yield mock

class TestGrammarAnalysisController:
    
    def test_analyze_grammar_success(self, mock_grammar_analyzer, mock_storage):
        """Test successful grammar analysis"""
        test_text = "This is a sample presentation text to analyze."
        test_report_id = "test-report-123"
        
        response = client.post(
            "/api/analyser/grammar/analyze",
            params={"text": test_text, "report_id": test_report_id}
        )
        
        data = response.json()
        assert data["message"] == "Grammar analysis completed successfully"
        assert data["score"] == 8
        assert data["weaknesses_count"] == 1
        
        mock_grammar_analyzer.assert_called_once_with(test_text)
        mock_storage.supabase.table.assert_called_once_with("UserReport")
        mock_storage.supabase.table().update.assert_called_once()
    
    def test_analyze_grammar_empty_text(self):
        """Test grammar analysis with empty text"""
        response = client.post(
            "/api/analyser/grammar/analyze",
            params={"text": "", "report_id": "test-report-123"}
        )
        
        assert "Text is too short or empty" in response.json()["detail"]
    
    def test_get_grammar_score(self, mock_auth, mock_storage):
        """Test retrieving grammar score"""
        response = client.get(
            "/api/analyser/grammar/score",
            params={"report_id": "test-report-123"}
        )
        
        data = response.json()
        assert "grammar_score" in data
        assert data["grammar_score"] == 8

        mock_storage.supabase.table.assert_called_with("UserReport")
        mock_storage.supabase.table().select.assert_called_with("scoreGrammar")
    
    def test_get_detailed_analysis(self, mock_auth, mock_storage):
        """Test retrieving detailed grammar sub-scores"""
        response = client.get(
            "/api/analyser/grammar/sub_scores",
            params={"report_id": "test-report-123"}
        )
        
        data = response.json()
        assert "analysis" in data
        assert data["analysis"]["grammar"] == 8
        assert data["analysis"]["structure"] == 7
        assert data["analysis"]["wordChoice"] == 9
        
        mock_storage.supabase.table.assert_called_with("UserReport")
        mock_storage.supabase.table().select.assert_called_with("subScoresGrammar")
    
    def test_get_identified_issues(self, mock_auth, mock_storage):
        """Test retrieving weakness topics"""
        response = client.get(
            "/api/analyser/grammar/weaknesses",
            params={"report_id": "test-report-123"}
        )
        
        data = response.json()
        assert "weakness_topics" in data
        assert len(data["weakness_topics"]) == 1
        assert data["weakness_topics"][0]["topic"] == "Sentence fragments"
        
        mock_storage.supabase.table.assert_called_with("UserReport")
        mock_storage.supabase.table().select.assert_called_with("weaknessTopicsGrammar")

