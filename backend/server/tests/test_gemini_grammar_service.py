import pytest
import os
import json
from unittest.mock import patch, MagicMock
from services.gemini_grammar_service import GeminiGrammarAnalyzer

@pytest.fixture
def mock_env_variables(monkeypatch):
    """Set up environment variables for testing"""
    monkeypatch.setenv("GEMINI_API_KEY", "test_api_key")
    
@pytest.fixture
def mock_genai():
    """Create a mock for the google.generativeai module"""
    with patch("services.gemini_grammar_service.genai") as mock:
        # Mock the list_models method to return a list of model objects
        model1 = MagicMock()
        model1.name = "gemini-pro"
        mock.list_models.return_value = [model1]
        
        # Mock the GenerativeModel class
        mock_model = MagicMock()
        mock_response = MagicMock()
        mock_response.text = json.dumps({
            "score": 7,
            "weaknesses": [
                {
                    "topic": "Run-on sentences",
                    "examples": ["This is a very long sentence that goes on and on."],
                    "suggestions": ["Break long sentences into shorter ones."]
                }
            ]
        })
        mock_model.generate_content.return_value = mock_response
        mock.GenerativeModel.return_value = mock_model
        
        yield mock

class TestGeminiGrammarAnalyzer:
    
    def test_init_with_valid_api_key(self, mock_env_variables, mock_genai):
        """Test initialization with a valid API key"""
        analyzer = GeminiGrammarAnalyzer()
        assert analyzer.model_name == "gemini-pro"
        mock_genai.configure.assert_called_once_with(api_key="test_api_key")
        
    def test_init_without_api_key(self, monkeypatch):
        """Test initialization with missing API key"""
        monkeypatch.delenv("GEMINI_API_KEY", raising=False)
        with pytest.raises(ValueError, match="Missing GEMINI_API_KEY environment variable"):
            GeminiGrammarAnalyzer()
    
    def test_get_best_model(self, mock_env_variables):
        """Test model selection logic"""
        analyzer = GeminiGrammarAnalyzer()
        
        available_models = ["gemini-pro", "text-bison"]
        assert analyzer._get_best_model(available_models) == "gemini-pro"
        
        available_models = ["other-model", "text-model"]
        assert analyzer._get_best_model(available_models) == "text-model"
        
        with pytest.raises(ValueError):
            analyzer._get_best_model([])
    
    def test_analyze_grammar(self, mock_env_variables, mock_genai):
        """Test grammar analysis with mock response"""
        analyzer = GeminiGrammarAnalyzer()
        result = analyzer.analyze_grammar("This is a sample text to analyze.")
        
        assert result["score"] == 7
        assert len(result["weaknesses"]) == 1
        assert result["weaknesses"][0]["topic"] == "Run-on sentences"
        
        mock_genai.GenerativeModel.assert_called_once_with("gemini-pro")
        mock_genai.GenerativeModel().generate_content.assert_called_once()
        
    def test_extract_json_from_response(self, mock_env_variables):
        """Test JSON extraction from various response formats"""
        analyzer = GeminiGrammarAnalyzer()
        
        valid_json = '{"score": 7, "weaknesses": []}'
        assert analyzer._extract_json_from_response(valid_json) == valid_json
        
        code_block = '```json\n{"score": 7, "weaknesses": []}\n```'
        expected = '{"score": 7, "weaknesses": []}'
        assert analyzer._extract_json_from_response(code_block) == expected
        
        text_surrounded = 'Here is the result:\n{"score": 7, "weaknesses": []}\nEnd of result.'
        assert analyzer._extract_json_from_response(text_surrounded) == '{"score": 7, "weaknesses": []}'
        
        assert analyzer._extract_json_from_response("Not JSON at all") is None
