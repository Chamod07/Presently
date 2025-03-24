import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from unittest.mock import patch, MagicMock
import sys
import os

# Add the parent directory to path to import the modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from controllers.audio_process_controller import router

# Create a test app
app = FastAPI()
app.include_router(router)
client = TestClient(app)

@pytest.mark.asyncio
@patch('controllers.audio_process_controller.convert_video_to_mp3')
async def test_convert_to_mp3_success(mock_convert):
    # Setup
    mock_convert.return_value = "tmp/123/audio/audio.mp3"
    
    # Test
    response = client.post("/convert_to_mp3?report_id=123")

    # Assert
    assert response.status_code == 200
    assert "Successfully converted video to MP3" in response.json()["message"]
    mock_convert.assert_called_once_with("123")

@pytest.mark.asyncio
@patch('controllers.audio_process_controller.convert_video_to_mp3')
async def test_convert_to_mp3_with_video_path(mock_convert):
    # Setup
    mock_convert.return_value = "tmp/123/audio/audio.mp3"
    
    # Test
    response = client.post("/convert_to_mp3?report_id=123&video_path=some/path/video.mp4")
    
    # Assert
    assert response.status_code == 200
    assert "Successfully converted video to MP3" in response.json()["message"]
    mock_convert.assert_called_once_with("123", "some/path/video.mp4")

@pytest.mark.asyncio
@patch('controllers.audio_process_controller.convert_video_to_mp3')
async def test_convert_to_mp3_file_not_found(mock_convert):
    # Setup
    mock_convert.side_effect = FileNotFoundError("Video file not found")
    
    # Test
    response = client.post("/convert_to_mp3?report_id=123")
    
    # Assert
    assert response.status_code == 404
    assert "Video file not found" in response.json()["detail"]

@pytest.mark.asyncio
@patch('controllers.audio_process_controller.transcribe_audio_to_text')
async def test_transcribe_success(mock_transcribe):
    # Setup
    mock_transcribe.return_value = "This is a test transcription"
    
    # Test
    response = client.post("/transcribe?report_id=123")
    
    # Assert
    assert response.status_code == 200
    assert response.json()["transcription"] == "This is a test transcription"
    mock_transcribe.assert_called_once_with("123")

@pytest.mark.asyncio
@patch('controllers.audio_process_controller.transcribe_audio_to_text')
async def test_transcribe_file_not_found(mock_transcribe):
    # Setup
    mock_transcribe.side_effect = FileNotFoundError("Audio file not found")
    
    # Test
    response = client.post("/transcribe?report_id=123")
    
    # Assert
    assert response.status_code == 404
    assert "Audio file not found" in response.json()["detail"]
