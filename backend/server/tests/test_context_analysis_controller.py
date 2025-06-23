import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from server.main import app
from controllers.context_analysis_controller import router, analyzer
from services.gemini_context_service import GeminiContextAnalyzer

client = TestClient(app)

@pytest.fixture
def mock_get_current_user_id():
    with patch("services.auth_service.get_current_user_id", return_value="test-user-id"):
        yield

@pytest.fixture
def mock_supabase():
    with patch("services.storage_service.supabase") as mock_supabase:

        mock_table = MagicMock()
        mock_supabase.table.return_value = mock_table
        
        mock_select = MagicMock()
        mock_table.select.return_value = mock_select
        mock_eq = MagicMock()
        mock_select.eq.return_value = mock_eq
        mock_execute = MagicMock()
        mock_eq.execute.return_value = mock_execute
        
        mock_update = MagicMock()
        mock_table.update.return_value = mock_update
        mock_update_eq = MagicMock()
        mock_update.eq.return_value = mock_update_eq
        mock_update_execute = MagicMock()
        mock_update_eq.execute.return_value = mock_update_execute
        
        mock_delete = MagicMock()
        mock_table.delete.return_value = mock_delete
        mock_delete_eq = MagicMock()
        mock_delete.eq.return_value = mock_delete_eq
        mock_delete_execute = MagicMock()
        mock_delete_eq.execute.return_value = mock_delete_execute
        
        yield mock_supabase

@pytest.fixture
def mock_gemini_analyzer():
    with patch.object(GeminiContextAnalyzer, 'analyze_presentation') as mock_analyze:
        mock_analyze.return_value = {
            "score": 8,
            "weaknesses": ["Weakness 1", "Weakness 2"],
            "subScores": {
                "relevance": 8,
                "coherence": 7,
                "engagement": 9
            }
        }
        
        with patch.object(GeminiContextAnalyzer, 'get_session_data') as mock_session:
            mock_session.return_value = {
                'session_topic': 'Test Topic',
                'session_type': 'Test Type',
                'session_goal': 'Test Goal',
                'audience': 'Test Audience'
            }
            yield

def test_analyze_context(mock_supabase, mock_gemini_analyzer):
    test_transcription = "This is a test transcription that is long enough to be valid."
    test_report_id = "test-report-id"
    
    response = client.post(
        "/analyze", 
        params={"transcription": test_transcription, "report_id": test_report_id}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Context analysis completed successfully"
    assert data["score"] == 8
    assert data["weaknesses_count"] == 2
    
    mock_supabase.table.assert_called_with("UserReport")
    mock_supabase.table().update.assert_called_once()

def test_analyze_context_invalid_transcription(mock_supabase, mock_gemini_analyzer):
    test_transcription = "" 
    test_report_id = "test-report-id"
    
    response = client.post(
        "/analyze", 
        params={"transcription": test_transcription, "report_id": test_report_id}
    )
    
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    assert "too short" in data["detail"]


def test_get_overall_score(mock_supabase, mock_get_current_user_id):

    mock_execute = mock_supabase.table().select().eq().execute
    mock_execute.return_value.data = [{"scoreContext": 8}]
    
    response = client.get("/score", params={"report_id": "test-report-id"})
    
    assert response.status_code == 200
    data = response.json()
    assert data["overall_score"] == 8
    assert data["user_id"] == "test-user-id"

def test_get_summery_score(mock_supabase, mock_get_current_user_id):

    mock_execute = mock_supabase.table().select().eq().execute
    sub_scores = {"relevance": 8, "coherence": 7, "engagement": 9}
    mock_execute.return_value.data = [{"subScoresContext": sub_scores}]

    response = client.get("/sub_scores", params={"report_id": "test-report-id"})
    
    assert response.status_code == 200
    data = response.json()
    assert data["content_analysis"] == sub_scores

def test_get_weaknesses(mock_supabase, mock_get_current_user_id):

    mock_execute = mock_supabase.table().select().eq().execute
    weaknesses = ["Weakness 1", "Weakness 2"]
    mock_execute.return_value.data = [{"weaknessTopicsContext": weaknesses}]

    response = client.get("/weaknesses", params={"report_id": "test-report-id"})
    
    assert response.status_code == 200
    data = response.json()
    assert data["weakness_topics"] == weaknesses


def test_list_reports(mock_supabase, mock_get_current_user_id):

    mock_supabase.table().select().range().execute.return_value.data = [
        {"reportId": "report1", "scoreContext": 8},
        {"reportId": "report2", "scoreContext": 7}
    ]
    mock_supabase.table().select().range().execute.return_value.error = None

    response = client.get("/reports", params={"limit": 10, "offset": 0})
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["reportId"] == "report1"
    assert data[1]["reportId"] == "report2"

def test_delete_report(mock_supabase, mock_get_current_user_id):

    mock_supabase.table().delete().eq().execute.return_value.error = None

    response = client.delete("/report/delete/test-report-id")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "deleted successfully" in data["message"]

def test_health_check(mock_get_current_user_id):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
