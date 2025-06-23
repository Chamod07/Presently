import pytest
import os
import shutil
from unittest.mock import patch, MagicMock, mock_open
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.audio_processing import convert_video_to_mp3, transcribe_audio_to_text

@pytest.fixture
def setup_directories():

    os.makedirs("tmp/test_report/video", exist_ok=True)
    os.makedirs("tmp/test_report/audio", exist_ok=True)
    
    with open("tmp/test_report/video/video.mp4", "w") as f:
        f.write("dummy video content")
    
    yield
    
    if os.path.exists("tmp/test_report"):
        shutil.rmtree("tmp/test_report")

@patch('subprocess.run')
def test_convert_video_to_mp3_success(mock_subprocess, setup_directories):
    # Setup
    mock_result = MagicMock()
    mock_result.returncode = 0
    mock_result.stderr = ""
    mock_subprocess.return_value = mock_result
    
    # Test
    output_path = convert_video_to_mp3("test_report")
    
    # Assert
    assert output_path == "tmp/test_report/audio/audio.mp3"
    mock_subprocess.assert_called_once()
    args = mock_subprocess.call_args[0][0]
    assert args[0] == "ffmpeg"
    assert "tmp/test_report/video/video.mp4" in args
    assert "tmp/test_report/audio/audio.mp3" in args

@patch('subprocess.run')
def test_convert_video_to_mp3_with_video_path(mock_subprocess, setup_directories):
    # Setup
    mock_result = MagicMock()
    mock_result.returncode = 0
    mock_result.stderr = ""
    mock_subprocess.return_value = mock_result
    
    custom_video_path = "tmp/custom_path/video.mp4"
    
    os.makedirs("tmp/custom_path", exist_ok=True)
    with open(custom_video_path, "w") as f:
        f.write("custom video content")
    
    try:
        # Test
        output_path = convert_video_to_mp3("test_report", custom_video_path)
        
        # Assert
        assert output_path == "tmp/test_report/audio/audio.mp3"
        mock_subprocess.assert_called_once()
        args = mock_subprocess.call_args[0][0]
        assert custom_video_path in args
    finally:
        # Cleanup
        if os.path.exists("tmp/custom_path"):
            shutil.rmtree("tmp/custom_path")

@patch('subprocess.run')
def test_convert_video_to_mp3_ffmpeg_error(mock_subprocess, setup_directories):
    # Setup
    mock_result = MagicMock()
    mock_result.returncode = 1
    mock_result.stderr = "FFMPEG error occurred"
    mock_subprocess.return_value = mock_result
    
    # Test and Assert
    with pytest.raises(Exception) as excinfo:
        convert_video_to_mp3("test_report")
    
    assert "Failed to convert video to MP3" in str(excinfo.value)

def test_convert_video_to_mp3_no_video_file(setup_directories):

    os.remove("tmp/test_report/video/video.mp4")
    
    # Test and Assert
    with pytest.raises(FileNotFoundError) as excinfo:
        convert_video_to_mp3("test_report")
    
    assert "No video files found" in str(excinfo.value)

@patch('services.audio_processing.transcribe_audio')
def test_transcribe_audio_to_text_success(mock_transcribe, setup_directories):
    # Setup
    mock_transcribe.return_value = ("This is a test transcription", None)
    
    os.makedirs("tmp/test_report/audio", exist_ok=True)
    with open("tmp/test_report/audio/audio.mp3", "w") as f:
        f.write("dummy audio content")
    
    with patch('builtins.open', mock_open()):
        # Test
        result = transcribe_audio_to_text("test_report")
        
        # Assert
        assert result == "This is a test transcription"
        mock_transcribe.assert_called_once_with("tmp/test_report/audio/audio.mp3", "test_report")

def test_transcribe_audio_to_text_no_audio_file(setup_directories):
    # Test and Assert
    with pytest.raises(FileNotFoundError) as excinfo:
        transcribe_audio_to_text("test_report")
    
    assert "Audio file not found" in str(excinfo.value)

@patch('services.audio_processing.transcribe_audio')
def test_transcribe_audio_to_text_empty_result(mock_transcribe, setup_directories):
    # Setup
    mock_transcribe.return_value = ("", None)
    
    os.makedirs("tmp/test_report/audio", exist_ok=True)
    with open("tmp/test_report/audio/audio.mp3", "w") as f:
        f.write("dummy audio content")
    
    # Test and Assert
    with pytest.raises(Exception) as excinfo:
        transcribe_audio_to_text("test_report")
    
    assert "Transcription failed or returned empty" in str(excinfo.value)
