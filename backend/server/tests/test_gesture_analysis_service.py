import pytest
import numpy as np
from unittest.mock import patch, MagicMock
import mediapipe as mp

# Import the module to test
from services.gesture_analysis_service import analyze_hand_gestures

@pytest.fixture
def mock_mp_pose():
    """Mock the MediaPipe pose solution"""
    with patch('services.gesture_analysis_service.mp') as mock_mp:
        # Create mock PoseLandmark enum values
        mock_mp.solutions.pose = MagicMock()
        mock_mp.solutions.pose.PoseLandmark = MagicMock()
        
        # Define PoseLandmark enum values for the landmarks we use
        mock_mp.solutions.pose.PoseLandmark.LEFT_WRIST = 15
        mock_mp.solutions.pose.PoseLandmark.RIGHT_WRIST = 16
        mock_mp.solutions.pose.PoseLandmark.LEFT_SHOULDER = 11
        mock_mp.solutions.pose.PoseLandmark.RIGHT_SHOULDER = 12
        
        yield mock_mp

@pytest.fixture
def mock_neutral_pose_landmarks():
    """Create landmarks for a neutral pose with hands at sides"""
    landmarks = []
    
    # Create 33 landmarks (MediaPipe pose has 33 landmarks)
    for i in range(33):
        landmark = MagicMock()
        landmark.x = 0.5  # Center of frame
        landmark.y = 0.5
        landmark.z = 0.0
        landmark.visibility = 0.9
        landmarks.append(landmark)
    
    # Set specific positions for landmarks we care about
    
    # Shoulders
    landmarks[11].x = 0.4  # LEFT_SHOULDER
    landmarks[11].y = 0.3
    
    landmarks[12].x = 0.6  # RIGHT_SHOULDER
    landmarks[12].y = 0.3
    
    # Wrists (neutral pose with hands at sides)
    landmarks[15].x = 0.35  # LEFT_WRIST
    landmarks[15].y = 0.6
    
    landmarks[16].x = 0.65  # RIGHT_WRIST
    landmarks[16].y = 0.6
    
    return landmarks

@pytest.fixture
def mock_raised_hands_pose_landmarks():
    """Create landmarks for a pose with hands raised above shoulders"""
    landmarks = []
    
    # Create 33 landmarks (MediaPipe pose has 33 landmarks)
    for i in range(33):
        landmark = MagicMock()
        landmark.x = 0.5  # Center of frame
        landmark.y = 0.5
        landmark.z = 0.0
        landmark.visibility = 0.9
        landmarks.append(landmark)
    
    # Set specific positions for landmarks we care about
    
    # Shoulders
    landmarks[11].x = 0.4  # LEFT_SHOULDER
    landmarks[11].y = 0.3
    
    landmarks[12].x = 0.6  # RIGHT_SHOULDER
    landmarks[12].y = 0.3
    
    # Wrists (hands raised above shoulders)
    landmarks[15].x = 0.3  # LEFT_WRIST
    landmarks[15].y = 0.2  # Above shoulder
    
    landmarks[16].x = 0.7  # RIGHT_WRIST
    landmarks[16].y = 0.2  # Above shoulder
    
    return landmarks

@pytest.fixture
def mock_wide_gesture_pose_landmarks():
    """Create landmarks for a pose with hands extended outward"""
    landmarks = []
    
    # Create 33 landmarks (MediaPipe pose has 33 landmarks)
    for i in range(33):
        landmark = MagicMock()
        landmark.x = 0.5  # Center of frame
        landmark.y = 0.5
        landmark.z = 0.0
        landmark.visibility = 0.9
        landmarks.append(landmark)
    
    # Set specific positions for landmarks we care about
    
    # Shoulders
    landmarks[11].x = 0.4  # LEFT_SHOULDER
    landmarks[11].y = 0.3
    
    landmarks[12].x = 0.6  # RIGHT_SHOULDER
    landmarks[12].y = 0.3
    
    # Wrists (hands extended outward)
    landmarks[15].x = 0.1  # LEFT_WRIST (far left)
    landmarks[15].y = 0.3  # Same height as shoulder
    
    landmarks[16].x = 0.9  # RIGHT_WRIST (far right)
    landmarks[16].y = 0.3  # Same height as shoulder
    
    return landmarks

class TestGestureAnalysisService:
    
    def test_analyze_neutral_pose(self, mock_mp_pose, mock_neutral_pose_landmarks):
        """Test gesture analysis with neutral pose (hands down)"""
        # Call the function with our mock landmarks
        result = analyze_hand_gestures(mock_neutral_pose_landmarks, 1)
        
        # Verify the structure of the result
        assert "left_extension" in result
        assert "right_extension" in result
        assert "avg_extension" in result
        assert "left_height" in result
        assert "right_height" in result
        assert "hand_separation" in result
        assert "frame" in result
        assert "movement_frequency" in result
        
        # Check specific values for neutral pose
        # In neutral pose, hands are down, so extension should be moderate 
        # and height should be negative (hands below shoulders)
        assert result["frame"] == 1
        assert result["left_extension"] > 0
        assert result["right_extension"] > 0
        assert result["left_height"] < 0  # Hands below shoulders (y increases downward)
        assert result["right_height"] < 0
        
        # Verify hand separation is calculated correctly
        # In our mock, distance from (0.35, 0.6) to (0.65, 0.6)
        expected_separation = np.linalg.norm(np.array([0.35, 0.6]) - np.array([0.65, 0.6]))
        assert abs(result["hand_separation"] - expected_separation) < 0.01
    
    def test_analyze_raised_hands_pose(self, mock_mp_pose, mock_raised_hands_pose_landmarks):
        """Test gesture analysis with raised hands pose"""
        # Call the function with our mock landmarks
        result = analyze_hand_gestures(mock_raised_hands_pose_landmarks, 1)
        
        # With raised hands, height should be positive (hands above shoulders)
        assert result["left_height"] > 0
        assert result["right_height"] > 0
        
        # Verify hand separation is calculated correctly
        # In our mock, distance from (0.3, 0.2) to (0.7, 0.2)
        expected_separation = np.linalg.norm(np.array([0.3, 0.2]) - np.array([0.7, 0.2]))
        assert abs(result["hand_separation"] - expected_separation) < 0.01
    
    def test_analyze_wide_gesture_pose(self, mock_mp_pose, mock_wide_gesture_pose_landmarks):
        """Test gesture analysis with wide extended hands pose"""
        # Call the function with our mock landmarks
        result = analyze_hand_gestures(mock_wide_gesture_pose_landmarks, 1)
        
        # With hands extended outward, extension should be high
        assert result["left_extension"] > 0.2
        assert result["right_extension"] > 0.2
        
        # Hand separation should be high
        assert result["hand_separation"] > 0.7  # Distance between 0.1 and 0.9 on x-axis
        
        # Verify hand separation is calculated correctly
        # In our mock, distance from (0.1, 0.3) to (0.9, 0.3)
        expected_separation = np.linalg.norm(np.array([0.1, 0.3]) - np.array([0.9, 0.3]))
        assert abs(result["hand_separation"] - expected_separation) < 0.01
    
    
    def test_analyze_hand_gestures_with_missing_landmarks(self, mock_mp_pose):
        """Test handling of missing or invalid landmarks"""
        # Create landmarks with some missing values
        incomplete_landmarks = []
        
        # Create 33 landmarks with low visibility 
        for i in range(33):
            landmark = MagicMock()
            landmark.x = 0.5
            landmark.y = 0.5
            landmark.z = 0.0
            landmark.visibility = 0.1  # Low visibility
            incomplete_landmarks.append(landmark)
        
        # Make some key landmarks None to simulate missing data
        incomplete_landmarks[15] = None  # LEFT_WRIST
        
        # We expect the function to handle this gracefully
        with pytest.raises(AttributeError):
            # This should raise an AttributeError since we're trying to access .x and .y
            # on a None value, but the test verifies that the error occurs where expected
            result = analyze_hand_gestures(incomplete_landmarks, 1)
