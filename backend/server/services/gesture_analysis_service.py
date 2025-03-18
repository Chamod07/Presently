import cv2
import mediapipe as mp
import numpy as np
import math
from collections import deque

def analyze_hand_gestures(landmarks, frame_count):
    """Analyze hand gestures and their effectiveness."""
    mp_pose = mp.solutions.pose
    
    # Extract wrist and shoulder landmarks
    left_wrist = np.array([landmarks[mp_pose.PoseLandmark.LEFT_WRIST].x,
                          landmarks[mp_pose.PoseLandmark.LEFT_WRIST].y])
    right_wrist = np.array([landmarks[mp_pose.PoseLandmark.RIGHT_WRIST].x,
                           landmarks[mp_pose.PoseLandmark.RIGHT_WRIST].y])
    left_shoulder = np.array([landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                             landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y])
    right_shoulder = np.array([landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                              landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y])
    
    # Calculate gesture space (distance from body)
    left_extension = np.linalg.norm(left_wrist - left_shoulder)
    right_extension = np.linalg.norm(right_wrist - right_shoulder)
    
    # Calculate gesture height (vertical position relative to shoulders)
    left_height = left_shoulder[1] - left_wrist[1]  # Positive when hands above shoulders
    right_height = right_shoulder[1] - right_wrist[1]
    
    # Calculate hand separation (distance between hands)
    hand_separation = np.linalg.norm(left_wrist - right_wrist)
    
    return {
        'left_extension': left_extension,
        'right_extension': right_extension,
        'left_height': left_height,
        'right_height': right_height,
        'hand_separation': hand_separation,
        'frame': frame_count
    }
