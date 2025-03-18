import cv2
import mediapipe as mp
import numpy as np
import math
from collections import deque

class FacialAnalyzer:
    def __init__(self):
        # Initialize MediaPipe Face Mesh
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=False,
            max_num_faces=1,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # Key facial landmarks indices
        # Eyes
        self.LEFT_EYE = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
        self.RIGHT_EYE = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
        
        # For gaze direction
        self.LEFT_IRIS = [474, 475, 476, 477]
        self.RIGHT_IRIS = [469, 470, 471, 472]
        
        # For smile detection
        self.MOUTH_OUTLINE = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]
        
        # For eyebrows
        self.LEFT_EYEBROW = [70, 63, 105, 66, 107, 55, 65, 52, 53, 46]
        self.RIGHT_EYEBROW = [300, 293, 334, 296, 336, 285, 295, 282, 283, 276]
        
        # History for temporal smoothing
        self.expression_history = deque(maxlen=30)  # Store recent expression scores
        self.gaze_history = deque(maxlen=30)  # Store recent gaze direction data
        
    def analyze_face(self, image, frame_count):
        """Analyze facial expressions and eye contact in an image"""
        # Convert to RGB for MediaPipe
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Process image with MediaPipe Face Mesh
        results = self.face_mesh.process(image_rgb)
        
        # Default return if no face detected
        face_data = {
            "face_detected": False,
            "frame": frame_count
        }
        
        if results.multi_face_landmarks:
            face_landmarks = results.multi_face_landmarks[0].landmark
            
            # Get image dimensions
            h, w = image.shape[:2]
            
            # Calculate facial expression metrics
            smile_score = self._calculate_smile_intensity(face_landmarks, w, h)
            eyebrows_score = self._calculate_eyebrow_movement(face_landmarks, w, h)
            eye_openness = self._calculate_eye_openness(face_landmarks, w, h)
            
            # Calculate gaze direction
            gaze_data = self._calculate_gaze_direction(face_landmarks, w, h)
            
            # Store in history for smoothing
            expression_score = (smile_score + eyebrows_score + eye_openness) / 3
            self.expression_history.append(expression_score)
            self.gaze_history.append(gaze_data)
            
            # Calculate smoothed metrics
            smoothed_expression = np.mean(self.expression_history) if self.expression_history else expression_score
            
            # Determine engagement level (0-100)
            engagement_level = min(100, smoothed_expression * 100)
            
            # Determine expression type
            expression_type = self._determine_expression_type(smile_score, eyebrows_score, eye_openness)
            
            # Determine eye contact quality
            eye_contact = self._determine_eye_contact_quality(gaze_data)
            
            face_data = {
                "face_detected": True,
                "frame": frame_count,
                "engagement_level": engagement_level,
                "expression_type": expression_type,
                "smile_intensity": smile_score,
                "eyebrow_movement": eyebrows_score,
                "eye_openness": eye_openness,
                "gaze_direction": gaze_data["direction"],
                "eye_contact_quality": eye_contact,
                "looking_at_audience": gaze_data["is_center"]
            }
        
        return face_data
    
    def _calculate_smile_intensity(self, landmarks, width, height):
        """Calculate smile intensity based on mouth shape"""
        if not landmarks:
            return 0
        
        # Extract mouth points
        mouth_points = []
        for idx in self.MOUTH_OUTLINE:
            point = landmarks[idx]
            mouth_points.append([point.x * width, point.y * height])
        
        mouth_points = np.array(mouth_points)
        
        # Calculate mouth width and height
        x_min = np.min(mouth_points[:, 0])
        x_max = np.max(mouth_points[:, 0])
        y_min = np.min(mouth_points[:, 1])
        y_max = np.max(mouth_points[:, 1])
        
        mouth_width = x_max - x_min
        mouth_height = y_max - y_min
        
        # Width-to-height ratio increases when smiling
        aspect_ratio = mouth_width / max(mouth_height, 1)
        
        # Normalize to 0-1 range (empirically determined thresholds)
        smile_intensity = max(0, min(1, (aspect_ratio - 1.5) / 2))
        
        return smile_intensity
    
    def _calculate_eyebrow_movement(self, landmarks, width, height):
        """Calculate eyebrow movement/expressiveness"""
        if not landmarks:
            return 0
        
        # Extract eyebrow and eye points
        left_eyebrow = []
        right_eyebrow = []
        left_eye = []
        right_eye = []
        
        for idx in self.LEFT_EYEBROW:
            point = landmarks[idx]
            left_eyebrow.append([point.x * width, point.y * height])
        
        for idx in self.RIGHT_EYEBROW:
            point = landmarks[idx]
            right_eyebrow.append([point.x * width, point.y * height])
        
        for idx in self.LEFT_EYE:
            point = landmarks[idx]
            left_eye.append([point.x * width, point.y * height])
        
        for idx in self.RIGHT_EYE:
            point = landmarks[idx]
            right_eye.append([point.x * width, point.y * height])
        
        # Convert to numpy arrays
        left_eyebrow = np.array(left_eyebrow)
        right_eyebrow = np.array(right_eyebrow)
        left_eye = np.array(left_eye)
        right_eye = np.array(right_eye)
        
        # Calculate eye centers
        left_eye_center = np.mean(left_eye, axis=0)
        right_eye_center = np.mean(right_eye, axis=0)
        
        # Calculate eyebrow centers
        left_eyebrow_center = np.mean(left_eyebrow, axis=0)
        right_eyebrow_center = np.mean(right_eyebrow, axis=0)
        
        # Calculate distance between eyebrow and eye
        left_distance = left_eyebrow_center[1] - left_eye_center[1]
        right_distance = right_eyebrow_center[1] - right_eye_center[1]
        
        # Average distance - higher means more expression
        avg_distance = (left_distance + right_distance) / 2
        
        # Normalize to 0-1 range (negative because y increases downward)
        eyebrow_score = max(0, min(1, (-avg_distance + 15) / 30))
        
        return eyebrow_score
    
    def _calculate_eye_openness(self, landmarks, width, height):
        """Calculate how open the eyes are"""
        if not landmarks:
            return 0
        
        # For each eye, compute vertical/horizontal ratio
        def eye_aspect_ratio(eye_indices):
            points = []
            for idx in eye_indices:
                point = landmarks[idx]
                points.append([point.x * width, point.y * height])
                
            points = np.array(points)
            
            # Compute width and height
            x_min, x_max = np.min(points[:, 0]), np.max(points[:, 0])
            y_min, y_max = np.min(points[:, 1]), np.max(points[:, 1])
            
            width = x_max - x_min
            height = y_max - y_min
            
            return height / width if width > 0 else 0
        
        left_ratio = eye_aspect_ratio(self.LEFT_EYE)
        right_ratio = eye_aspect_ratio(self.RIGHT_EYE)
        
        # Average aspect ratio - higher means more open
        avg_ratio = (left_ratio + right_ratio) / 2
        
        # Normalize to 0-1 range
        openness_score = max(0, min(1, (avg_ratio - 0.2) / 0.3))
        
        return openness_score
    
    def _calculate_gaze_direction(self, landmarks, width, height):
        """Calculate gaze direction to determine eye contact"""
        if not landmarks:
            return {"direction": "unknown", "is_center": False, "angle": 0}
        
        # Extract eye and iris landmarks
        left_eye_points = []
        right_eye_points = []
        left_iris_points = []
        right_iris_points = []
        
        for idx in self.LEFT_EYE:
            point = landmarks[idx]
            left_eye_points.append([point.x * width, point.y * height])
        
        for idx in self.RIGHT_EYE:
            point = landmarks[idx]
            right_eye_points.append([point.x * width, point.y * height])
        
        for idx in self.LEFT_IRIS:
            point = landmarks[idx]
            left_iris_points.append([point.x * width, point.y * height])
        
        for idx in self.RIGHT_IRIS:
            point = landmarks[idx]
            right_iris_points.append([point.x * width, point.y * height])
        
        # Convert to numpy arrays
        left_eye = np.array(left_eye_points)
        right_eye = np.array(right_eye_points)
        left_iris = np.array(left_iris_points) if left_iris_points else np.array(left_eye).mean(axis=0, keepdims=True)
        right_iris = np.array(right_iris_points) if right_iris_points else np.array(right_eye).mean(axis=0, keepdims=True)
        
        # Calculate eye centers
        left_eye_center = np.mean(left_eye, axis=0)
        right_eye_center = np.mean(right_eye, axis=0)
        
        # Calculate iris centers
        left_iris_center = np.mean(left_iris, axis=0)
        right_iris_center = np.mean(right_iris, axis=0)
        
        # Calculate relative position of iris within eye
        left_rel_x = (left_iris_center[0] - left_eye_center[0]) / (np.max(left_eye[:, 0]) - np.min(left_eye[:, 0])) if left_eye.size > 0 else 0
        right_rel_x = (right_iris_center[0] - right_eye_center[0]) / (np.max(right_eye[:, 0]) - np.min(right_eye[:, 0])) if right_eye.size > 0 else 0
        
        # Average relative x position
        avg_rel_x = (left_rel_x + right_rel_x) / 2
        
        # Determine gaze direction
        if avg_rel_x < -0.15:
            direction = "looking-left"
            is_center = False
        elif avg_rel_x > 0.15:
            direction = "looking-right"
            is_center = False
        else:
            direction = "center"
            is_center = True
        
        return {
            "direction": direction,
            "is_center": is_center,
            "angle": avg_rel_x * 45  # Approximate gaze angle
        }
    
    def _determine_expression_type(self, smile, eyebrows, eye_openness):
        """Determine the type of facial expression based on measurements"""
        # Smiling expression
        if smile > 0.5:
            if eyebrows > 0.6:
                return "enthusiastic"
            return "smiling"
        
        # Surprised/interested expression
        if eyebrows > 0.6 and eye_openness > 0.6:
            return "surprised"
        
        # Neutral expression
        if 0.3 <= smile <= 0.5 and 0.3 <= eyebrows <= 0.6:
            return "neutral"
        
        # Serious expression
        if smile < 0.3 and eyebrows < 0.4:
            return "serious"
        
        return "neutral"
    
    def _determine_eye_contact_quality(self, gaze_data):
        """Determine the quality of eye contact"""
        if not self.gaze_history:
            return "insufficient-data"
        
        # Count frames with centered gaze
        center_count = sum(1 for g in self.gaze_history if g["is_center"])
        center_ratio = center_count / len(self.gaze_history)
        
        if center_ratio >= 0.8:
            return "excellent"
        elif center_ratio >= 0.6:
            return "good"
        elif center_ratio >= 0.4:
            return "fair"
        else:
            return "poor"

def analyze_facial_engagement(video_path, sample_rate=5):
    """
    Analyze facial engagement in a video.
    
    Args:
        video_path: Path to the video file
        sample_rate: Process every Nth frame
    
    Returns:
        Dict with facial engagement analysis results
    """
    cap = cv2.VideoCapture(video_path)
    facial_analyzer = FacialAnalyzer()
    
    frame_count = 0
    processed_frames = 0
    face_detected_frames = 0
    expression_data = []
    frame_metrics = []
    
    # Aggregate metrics
    engagement_scores = []
    smile_intensities = []
    eye_contact_frames = 0
    expression_counts = {
        "neutral": 0,
        "smiling": 0,
        "enthusiastic": 0,
        "serious": 0,
        "surprised": 0
    }
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_count += 1
        
        # Process at specified sample rate
        if frame_count % sample_rate != 0:
            continue
        
        processed_frames += 1
        
        # Analyze face in current frame
        face_data = facial_analyzer.analyze_face(frame, frame_count)
        
        if face_data["face_detected"]:
            face_detected_frames += 1
            
            # Collect metrics
            engagement_scores.append(face_data["engagement_level"])
            smile_intensities.append(face_data["smile_intensity"])
            
            if face_data["looking_at_audience"]:
                eye_contact_frames += 1
            
            # Count expression types
            if face_data["expression_type"] in expression_counts:
                expression_counts[face_data["expression_type"]] += 1
            
            # Add to frame metrics
            frame_metrics.append(face_data)
    
    cap.release()
    
    # Calculate overall metrics
    detection_rate = face_detected_frames / processed_frames * 100 if processed_frames > 0 else 0
    
    # Calculate engagement statistics
    avg_engagement = np.mean(engagement_scores) if engagement_scores else 0
    max_engagement = np.max(engagement_scores) if engagement_scores else 0
    min_engagement = np.min(engagement_scores) if engagement_scores else 0
    
    # Calculate eye contact ratio
    eye_contact_ratio = eye_contact_frames / face_detected_frames * 100 if face_detected_frames > 0 else 0
    
    # Find dominant expression
    dominant_expression = max(expression_counts.items(), key=lambda x: x[1])[0] if any(expression_counts.values()) else "unknown"
    
    # Calculate expression distribution
    expression_distribution = {}
    for expr, count in expression_counts.items():
        expression_distribution[expr] = count / face_detected_frames * 100 if face_detected_frames > 0 else 0
    
    # Generate feedback based on metrics
    facial_issues = []
    
    if avg_engagement < 30:
        facial_issues.append({
            "issue": "Low facial engagement",
            "frequency": 100 - avg_engagement,
            "suggestions": ["Show more facial expressions", "Appear more enthusiastic about your topic", "Practice engaging facial expressions in a mirror"]
        })
    
    if eye_contact_ratio < 60:
        facial_issues.append({
            "issue": "Insufficient eye contact",
            "frequency": 100 - eye_contact_ratio,
            "suggestions": ["Focus on looking directly at the camera/audience", "Avoid looking down at notes too frequently", "Practice maintaining consistent eye contact"]
        })
    
    if expression_distribution.get("serious", 0) > 70:
        facial_issues.append({
            "issue": "Overly serious expression",
            "frequency": expression_distribution.get("serious", 0),
            "suggestions": ["Incorporate more smiles into your presentation", "Vary your facial expressions", "Practice showing enthusiasm through your facial expressions"]
        })
    
    # Compile final results
    results = {
        "detection_rate": detection_rate,
        "total_frames": frame_count,
        "processed_frames": processed_frames,
        "face_detected_frames": face_detected_frames,
        "engagement_metrics": {
            "average": avg_engagement,
            "max": max_engagement,
            "min": min_engagement
        },
        "eye_contact_ratio": eye_contact_ratio,
        "dominant_expression": dominant_expression,
        "expression_distribution": expression_distribution,
        "facial_issues": facial_issues,
        "frame_metrics": frame_metrics
    }
    
    return results
