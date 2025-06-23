import pytest
import numpy as np
from unittest.mock import patch, MagicMock, call
import cv2
import sys
import os

# Import the module to test
from services.facial_analysis_service import FacialAnalyzer, analyze_facial_engagement

# Mock MediaPipe and OpenCV
@pytest.fixture
def mock_mediapipe():
    """Mock the MediaPipe face mesh solution"""
    with patch('services.facial_analysis_service.mp') as mock_mp:
        # Create nested mocks for face_mesh
        mock_face_mesh = MagicMock()
        mock_mp.solutions.face_mesh = MagicMock()
        mock_mp.solutions.face_mesh.FaceMesh.return_value = mock_face_mesh
        
        yield mock_mp

@pytest.fixture
def mock_cv2():
    """Mock OpenCV functionality"""
    with patch('services.facial_analysis_service.cv2') as mock_cv2:
        # Setup VideoCapture mock
        mock_video = MagicMock()
        mock_video.isOpened.return_value = True
        
        # Create 10 test frames - first return True, then False to end the loop
        mock_frames = [(True, np.zeros((480, 640, 3), dtype=np.uint8)) for _ in range(10)]
        mock_frames.append((False, None))  # End of video
        mock_video.read.side_effect = mock_frames
        
        mock_cv2.VideoCapture.return_value = mock_video
        mock_cv2.cvtColor.return_value = np.zeros((480, 640, 3), dtype=np.uint8)
        
        yield mock_cv2

@pytest.fixture
def mock_face_landmarks():
    """Create mock face landmarks for testing"""
    landmarks = []
    
    # Generate 478 mock landmarks (MediaPipe face mesh has 468 landmarks but we need more for iris)
    for i in range(478):
        landmark = MagicMock()
        
        # Set different x, y values based on landmark index to simulate real landmarks
        landmark.x = 0.4 + (0.2 * (i % 5) / 5)  # Range from 0.4 to 0.6
        landmark.y = 0.4 + (0.2 * (i % 7) / 7)  # Range from 0.4 to 0.6
        landmark.z = 0.0
        
        landmarks.append(landmark)
    
    # Adjust specific landmarks for mouth, eyes, etc.
    # Left eye landmarks
    for idx in [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].y = 0.4
        
    # Right eye landmarks  
    for idx in [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].y = 0.4
    
    # Mouth landmarks - set to simulate a smile (wider than tall)
    for idx in [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].x = 0.5 + (idx % 8) * 0.01  # Make mouth wide
            landmarks[idx].y = 0.6 + (idx % 3) * 0.01  # Make mouth short for smile
    
    # Eyebrow landmarks - positioned above eyes
    for idx in [70, 63, 105, 66, 107, 55, 65, 52, 53, 46]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].y = 0.3  # Positioned above eyes
    
    for idx in [300, 293, 334, 296, 336, 285, 295, 282, 283, 276]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].y = 0.3  # Positioned above eyes
        
    # Left and right iris landmarks
    for idx in [474, 475, 476, 477, 469, 470, 471, 472]:
        if idx < len(landmarks):  # Make sure index is valid
            landmarks[idx].x = 0.5  # Centered iris = looking at camera
        
    return landmarks

@pytest.fixture
def mock_face_results(mock_face_landmarks):
    """Create mock face detection results"""
    results = MagicMock()
    
    # Create face_landmarks structure
    face_landmarks = MagicMock()
    face_landmarks.landmark = mock_face_landmarks
    results.multi_face_landmarks = [face_landmarks]
    
    return results

class TestFacialAnalyzer:
    
    def test_init(self, mock_mediapipe):
        """Test initialization of the FacialAnalyzer class"""
        analyzer = FacialAnalyzer()
        
        # Verify MediaPipe face mesh was initialized
        mock_mediapipe.solutions.face_mesh.FaceMesh.assert_called_once_with(
            static_image_mode=False,
            max_num_faces=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # Verify the landmark indices are defined
        assert len(analyzer.LEFT_EYE) > 0
        assert len(analyzer.RIGHT_EYE) > 0
        assert len(analyzer.LEFT_IRIS) > 0
        assert len(analyzer.RIGHT_IRIS) > 0
        assert len(analyzer.MOUTH_OUTLINE) > 0
        assert len(analyzer.LEFT_EYEBROW) > 0
        assert len(analyzer.RIGHT_EYEBROW) > 0
        
    def test_analyze_face_no_detection(self, mock_mediapipe):
        """Test analyze_face when no face is detected"""
        analyzer = FacialAnalyzer()
        
        # Set up the face mesh to return no faces
        mock_results = MagicMock()
        mock_results.multi_face_landmarks = None
        analyzer.face_mesh.process.return_value = mock_results
        
        # Create a test image
        test_image = np.zeros((480, 640, 3), dtype=np.uint8)
        
        # Call analyze_face
        result = analyzer.analyze_face(test_image, 1)
        
        # Verify results
        assert result["face_detected"] is False
        assert result["frame"] == 1
        
    def test_analyze_face_with_detection(self, mock_mediapipe, mock_face_results):
        """Test analyze_face when a face is detected"""
        analyzer = FacialAnalyzer()
        
        # Set up the face mesh to return a face
        analyzer.face_mesh.process.return_value = mock_face_results
        
        # Create a test image
        test_image = np.zeros((480, 640, 3), dtype=np.uint8)
        
        # Call analyze_face
        result = analyzer.analyze_face(test_image, 1)
        
        # Verify results
        assert result["face_detected"] is True
        assert result["frame"] == 1
        assert "engagement_level" in result
        assert "expression_type" in result
        assert "smile_intensity" in result
        assert "eyebrow_movement" in result
        assert "eye_openness" in result
        assert "gaze_direction" in result
        assert "eye_contact_quality" in result
        assert "looking_at_audience" in result
        
    def test_calculate_smile_intensity(self, mock_mediapipe, mock_face_landmarks):
        """Test the smile intensity calculation"""
        analyzer = FacialAnalyzer()
        
        # Test with valid landmarks
        smile_intensity = analyzer._calculate_smile_intensity(mock_face_landmarks, 640, 480)
        assert 0 <= smile_intensity <= 1
        
        # Test with empty landmarks
        assert analyzer._calculate_smile_intensity([], 640, 480) == 0
        
    def test_calculate_eyebrow_movement(self, mock_mediapipe, mock_face_landmarks):
        """Test the eyebrow movement calculation"""
        analyzer = FacialAnalyzer()
        
        # Test with valid landmarks
        eyebrow_score = analyzer._calculate_eyebrow_movement(mock_face_landmarks, 640, 480)
        assert 0 <= eyebrow_score <= 1
        
        # Test with empty landmarks
        assert analyzer._calculate_eyebrow_movement([], 640, 480) == 0
        
    def test_calculate_eye_openness(self, mock_mediapipe, mock_face_landmarks):
        """Test the eye openness calculation"""
        analyzer = FacialAnalyzer()
        
        # Test with valid landmarks
        openness_score = analyzer._calculate_eye_openness(mock_face_landmarks, 640, 480)
        assert 0 <= openness_score <= 1
        
        # Test with empty landmarks
        assert analyzer._calculate_eye_openness([], 640, 480) == 0
        
    def test_calculate_gaze_direction(self, mock_mediapipe, mock_face_landmarks):
        """Test the gaze direction calculation"""
        analyzer = FacialAnalyzer()
        
        # Test with valid landmarks
        gaze_data = analyzer._calculate_gaze_direction(mock_face_landmarks, 640, 480)
        assert "direction" in gaze_data
        assert "is_center" in gaze_data
        assert "angle" in gaze_data
        
        # Test with empty landmarks
        empty_gaze = analyzer._calculate_gaze_direction([], 640, 480)
        assert empty_gaze["direction"] == "unknown"
        assert empty_gaze["is_center"] is False
        
    def test_determine_expression_type(self, mock_mediapipe):
        """Test the expression type determination"""
        analyzer = FacialAnalyzer()
        
        # Test various expression types
        assert analyzer._determine_expression_type(0.6, 0.7, 0.5) == "enthusiastic"
        assert analyzer._determine_expression_type(0.6, 0.3, 0.5) == "smiling"
        assert analyzer._determine_expression_type(0.3, 0.7, 0.7) == "surprised"
        assert analyzer._determine_expression_type(0.4, 0.4, 0.4) == "neutral"
        assert analyzer._determine_expression_type(0.2, 0.3, 0.4) == "serious"
        
    def test_determine_eye_contact_quality(self, mock_mediapipe):
        """Test the eye contact quality determination"""
        analyzer = FacialAnalyzer()
        
        # Empty history
        assert analyzer._determine_eye_contact_quality({"is_center": True}) == "insufficient-data"
        
        # Fill history with different gaze data
        # 90% center = excellent
        analyzer.gaze_history = [{"is_center": True} for _ in range(9)]
        analyzer.gaze_history.append({"is_center": False})
        assert analyzer._determine_eye_contact_quality({"is_center": True}) == "excellent"
        
        # 70% center = good
        analyzer.gaze_history = [{"is_center": True} for _ in range(7)]
        analyzer.gaze_history.extend([{"is_center": False} for _ in range(3)])
        assert analyzer._determine_eye_contact_quality({"is_center": True}) == "good"
        
        # 50% center = fair
        analyzer.gaze_history = [{"is_center": True} for _ in range(5)]
        analyzer.gaze_history.extend([{"is_center": False} for _ in range(5)])
        assert analyzer._determine_eye_contact_quality({"is_center": True}) == "fair"
        
        # 30% center = poor
        analyzer.gaze_history = [{"is_center": True} for _ in range(3)]
        analyzer.gaze_history.extend([{"is_center": False} for _ in range(7)])
        assert analyzer._determine_eye_contact_quality({"is_center": True}) == "poor"


class TestFacialEngagementAnalysis:
    
    def test_analyze_facial_engagement(self, mock_cv2, mock_mediapipe, mock_face_landmarks):
        """Test the analyze_facial_engagement function"""
        # Configure the mock face mesh to return positive results for half of the frames
        face_mesh_instance = mock_mediapipe.solutions.face_mesh.FaceMesh.return_value
        
        # Configure mock results for alternating frames (face detected, no face detected)
        mock_faces = []
        for i in range(10):
            result = MagicMock()
            if i % 2 == 0:  # Face detected in even frames
                face_landmark = MagicMock()
                face_landmark.landmark = mock_face_landmarks
                result.multi_face_landmarks = [face_landmark]
            else:
                result.multi_face_landmarks = None
            mock_faces.append(result)
        
        face_mesh_instance.process.side_effect = mock_faces
        
        # Run the analysis
        results = analyze_facial_engagement("test_video.mp4", sample_rate=1)
        
        # Verify the results structure
        assert "detection_rate" in results
        assert "total_frames" in results
        assert "processed_frames" in results
        assert "face_detected_frames" in results
        assert "engagement_metrics" in results
        assert "eye_contact_ratio" in results
        assert "dominant_expression" in results
        assert "expression_distribution" in results
        assert "facial_issues" in results
        assert "frame_metrics" in results
        
        # Verify counts
        assert results["total_frames"] == 10
        assert results["processed_frames"] == 10
        assert results["face_detected_frames"] == 5  # Half the frames have faces
        
        # Verify OpenCV was used properly
        mock_cv2.VideoCapture.assert_called_once_with("test_video.mp4")
        assert mock_cv2.VideoCapture().read.call_count == 11  # 10 frames + 1 to exit loop
        
    def test_analyze_facial_engagement_no_faces(self, mock_cv2, mock_mediapipe):
        """Test analyze_facial_engagement when no faces are detected"""
        # Configure the mock face mesh to return negative results
        face_mesh_instance = mock_mediapipe.solutions.face_mesh.FaceMesh.return_value
        
        # No faces detected in any frame
        mock_results = MagicMock()
        mock_results.multi_face_landmarks = None
        face_mesh_instance.process.return_value = mock_results
        
        # Run the analysis
        results = analyze_facial_engagement("test_video.mp4", sample_rate=1)
        
        # Verify the results
        assert results["detection_rate"] == 0
        assert results["face_detected_frames"] == 0
        assert results["engagement_metrics"]["average"] == 0
        assert len(results["facial_issues"]) > 0  # Should report issues with no face detection
        
    def test_analyze_facial_engagement_with_sample_rate(self, mock_cv2, mock_mediapipe, mock_face_landmarks):
        """Test analyze_facial_engagement with different sample rates"""
        # Configure the mock face mesh to return positive results
        face_mesh_instance = mock_mediapipe.solutions.face_mesh.FaceMesh.return_value
        
        # Create a mock result with face landmarks
        mock_results = MagicMock()
        face_landmark = MagicMock()
        face_landmark.landmark = mock_face_landmarks
        mock_results.multi_face_landmarks = [face_landmark]
        
        # Always return the same result with a face for simplicity
        face_mesh_instance.process.return_value = mock_results
        
        # Run with sample_rate=2 (analyze every other frame)
        results = analyze_facial_engagement("test_video.mp4", sample_rate=2)
        
        # With 10 frames and sample_rate=2, we should process 5 frames
        assert results["total_frames"] == 10
        assert results["processed_frames"] == 5
        
        # Since all frames have faces in this mock, all processed frames should have faces detected
        assert results["face_detected_frames"] == 5
