import pytest
import os
import json
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from fastapi import HTTPException
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from controllers.body_language_analysis_controller import (
    get_body_language_score, 
    get_body_language_weaknesses,
    analyze_video
)

client = TestClient(app)

class TestBodyLanguageAnalysisController:
    """Tests for the body language analysis controller."""

    @patch('controllers.body_language_analysis_controller.storage_service')
    async def test_get_body_language_score_success(self, mock_storage_service):
        """Test successful retrieval of body language score."""
        # Setup
        report_id = "test-report-id"
        user_id = "test-user-id"
        mock_response = MagicMock()
        mock_response.data = [{"scoreBodyLanguage": 85}]
        mock_storage_service.supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response
        
        # Execute
        result = await get_body_language_score(report_id, user_id)
        
        # Assert
        assert result == {"scoreBodyLanguage": 85}
        mock_storage_service.supabase.table.assert_called_once_with("UserReport")
        mock_storage_service.supabase.table.return_value.select.assert_called_once_with("scoreBodyLanguage")
        mock_storage_service.supabase.table.return_value.select.return_value.eq.assert_called_once_with("reportId", report_id)

    @patch('controllers.body_language_analysis_controller.storage_service')
    async def test_get_body_language_score_not_found(self, mock_storage_service):
        """Test body language score not found."""
        # Setup
        report_id = "test-report-id"
        user_id = "test-user-id"
        mock_response = MagicMock()
        mock_response.data = []
        mock_storage_service.supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response
        
        # Execute & Assert
        with pytest.raises(HTTPException) as exc_info:
            await get_body_language_score(report_id, user_id)
        
        assert exc_info.value.status_code == 404
        assert exc_info.value.detail == "Body language score not found"

    @patch('controllers.body_language_analysis_controller.storage_service')
    async def test_get_body_language_score_null(self, mock_storage_service):
        """Test body language score is null."""
        # Setup
        report_id = "test-report-id"
        user_id = "test-user-id"
        mock_response = MagicMock()
        mock_response.data = [{"scoreBodyLanguage": None}]
        mock_storage_service.supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response
        
        # Execute & Assert
        with pytest.raises(HTTPException) as exc_info:
            await get_body_language_score(report_id, user_id)
        
        assert exc_info.value.status_code == 404
        assert exc_info.value.detail == "Body language score not found"

    @patch('controllers.body_language_analysis_controller.storage_service')
    async def test_get_body_language_weaknesses_success(self, mock_storage_service):
        """Test successful retrieval of body language weaknesses."""
        # Setup
        report_id = "test-report-id"
        user_id = "test-user-id"
        mock_response = MagicMock()
        weakness_topics = ["posture", "gestures"]
        mock_response.data = [{"weaknessTopicsBodylan": weakness_topics}]
        mock_storage_service.supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response
        
        # Execute
        result = await get_body_language_weaknesses(report_id, user_id)
        
        # Assert
        assert result == {"weaknessTopics": weakness_topics}
        mock_storage_service.supabase.table.assert_called_once_with("UserReport")
        mock_storage_service.supabase.table.return_value.select.assert_called_once_with("weaknessTopicsBodylan")
        mock_storage_service.supabase.table.return_value.select.return_value.eq.assert_called_once_with("reportId", report_id)

    @patch('controllers.body_language_analysis_controller.storage_service')
    async def test_get_body_language_weaknesses_not_found(self, mock_storage_service):
        """Test body language weaknesses not found."""
        # Setup
        report_id = "test-report-id"
        user_id = "test-user-id"
        mock_response = MagicMock()
        mock_response.data = []
        mock_storage_service.supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response
        
        # Execute & Assert
        with pytest.raises(HTTPException) as exc_info:
            await get_body_language_weaknesses(report_id, user_id)
        
        assert exc_info.value.status_code == 404
        assert exc_info.value.detail == "No body language weaknesses found"

    @patch('controllers.body_language_analysis_controller.os.path.exists')
    @patch('controllers.body_language_analysis_controller.pose_analysis_service')
    async def test_analyze_video_success(self, mock_pose_service, mock_path_exists):
        """Test successful video analysis."""
        # Setup
        report_id = "test-report-id"
        video_path = "tmp/test-report-id/video/video.mp4"
        mock_path_exists.return_value = True
        mock_pose_service.generate_posture_report.return_value = "tmp/test-report-id/report.json"
        
        # Execute
        result = await analyze_video(report_id)
        
        # Assert
        assert result["status"] == "success"
        assert result["message"] == "Body language analysis complete"
        assert result["report_file"] == "tmp/test-report-id/report.json"
        mock_pose_service.generate_posture_report.assert_called_once_with(video_path, report_id)

    @patch('controllers.body_language_analysis_controller.os.path.exists')
    async def test_analyze_video_file_not_found(self, mock_path_exists):
        """Test video analysis with missing file."""
        # Setup
        report_id = "test-report-id"
        mock_path_exists.return_value = False
        
        # Execute & Assert
        with pytest.raises(HTTPException) as exc_info:
            await analyze_video(report_id)
        
        assert exc_info.value.status_code == 404
        assert "Video file not found" in exc_info.value.detail

    @patch('controllers.body_language_analysis_controller.os.path.exists')
    @patch('controllers.body_language_analysis_controller.pose_analysis_service')
    async def test_analyze_video_processing_error(self, mock_pose_service, mock_path_exists):
        """Test video analysis with processing error."""
        # Setup
        report_id = "test-report-id"
        mock_path_exists.return_value = True
        mock_pose_service.generate_posture_report.side_effect = Exception("Processing error")
        
        # Execute & Assert
        with pytest.raises(HTTPException) as exc_info:
            await analyze_video(report_id)
        
        assert exc_info.value.status_code == 500
        assert "Body language analysis failed" in exc_info.value.detail
