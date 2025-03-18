import cv2
import mediapipe as mp
import numpy as np
import os
import math
from datetime import datetime
from collections import deque
from scipy.signal import savgol_filter


def calculate_tilt_angle(point1, point2):
    """Calculate the tilt angle between two points relative to the horizontal axis."""
    dx = point2[0] - point1[0]
    dy = point2[1] - point1[1]
    angle = math.degrees(math.atan2(dy, dx))
    return abs(angle)


def calculate_visibility_score(landmarks, visibility_threshold=0.5):
    """Calculate visibility score for key body parts."""
    key_landmarks = [
        'LEFT_SHOULDER', 'RIGHT_SHOULDER', 
        'LEFT_HIP', 'RIGHT_HIP',
        'LEFT_EAR', 'RIGHT_EAR',
        'NOSE'
    ]
    
    mp_pose = mp.solutions.pose
    visibility_scores = {}
    
    for landmark_name in key_landmarks:
        landmark_idx = getattr(mp_pose.PoseLandmark, landmark_name)
        if landmark_idx < len(landmarks):
            visibility = landmarks[landmark_idx].visibility
            visibility_scores[landmark_name] = visibility
    
    # Determine which body parts are reliably visible
    upper_body_visible = all(visibility_scores.get(part, 0) > visibility_threshold 
                           for part in ['LEFT_SHOULDER', 'RIGHT_SHOULDER'])
    
    lower_body_visible = all(visibility_scores.get(part, 0) > visibility_threshold 
                           for part in ['LEFT_HIP', 'RIGHT_HIP'])
    
    face_visible = all(visibility_scores.get(part, 0) > visibility_threshold 
                      for part in ['LEFT_EAR', 'RIGHT_EAR', 'NOSE'])
    
    return {
        'upper_body_visible': upper_body_visible,
        'lower_body_visible': lower_body_visible,
        'face_visible': face_visible,
        'scores': visibility_scores
    }


def calculate_head_position(landmarks, mp_pose):
    """Calculate head position metrics (tilt, forward/backward lean)."""
    if len(landmarks) <= mp_pose.PoseLandmark.RIGHT_EAR:
        return None
        
    # Get ear and shoulder landmarks
    left_ear = np.array([landmarks[mp_pose.PoseLandmark.LEFT_EAR].x, 
                         landmarks[mp_pose.PoseLandmark.LEFT_EAR].y])
    right_ear = np.array([landmarks[mp_pose.PoseLandmark.RIGHT_EAR].x, 
                          landmarks[mp_pose.PoseLandmark.RIGHT_EAR].y])
    left_shoulder = np.array([landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x, 
                             landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y])
    right_shoulder = np.array([landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x, 
                              landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y])
    nose = np.array([landmarks[mp_pose.PoseLandmark.NOSE].x, 
                    landmarks[mp_pose.PoseLandmark.NOSE].y])
    
    # Visibility checks
    left_ear_vis = landmarks[mp_pose.PoseLandmark.LEFT_EAR].visibility > 0.5
    right_ear_vis = landmarks[mp_pose.PoseLandmark.RIGHT_EAR].visibility > 0.5
    
    # Calculate ear midpoint if both ears are visible
    if left_ear_vis and right_ear_vis:
        ear_midpoint = (left_ear + right_ear) / 2
    elif left_ear_vis:
        ear_midpoint = left_ear
    elif right_ear_vis:
        ear_midpoint = right_ear
    else:
        return None
    
    # Calculate shoulder midpoint
    shoulder_midpoint = (left_shoulder + right_shoulder) / 2
    
    # Head tilt (left-right tilt angle)
    if left_ear_vis and right_ear_vis:
        head_tilt = calculate_tilt_angle(left_ear, right_ear)
    else:
        head_tilt = None
    
    # Forward lean (angle between vertical line from shoulders and line to head)
    vertical_vector = np.array([0, -1])  # Up direction in image coordinates
    head_vector = ear_midpoint - shoulder_midpoint
    head_vector_normalized = head_vector / np.linalg.norm(head_vector)
    
    # Calculate forward/backward lean using dot product with vertical vector
    forward_lean = math.degrees(math.acos(np.clip(np.dot(vertical_vector, head_vector_normalized), -1.0, 1.0)))
    
    # For side view or partial visibility
    nose_to_shoulder_distance = None
    if landmarks[mp_pose.PoseLandmark.NOSE].visibility > 0.5:
        # Calculate horizontal distance between nose and shoulder midpoint
        nose_to_shoulder_distance = abs(nose[0] - shoulder_midpoint[0])
    
    return {
        'head_tilt': head_tilt,
        'forward_lean': forward_lean,
        'nose_to_shoulder_distance': nose_to_shoulder_distance
    }


def calculate_spine_alignment(landmarks, mp_pose):
    """Calculate spine alignment metrics."""
    # Check if necessary landmarks are available
    required_landmarks = [
        mp_pose.PoseLandmark.LEFT_SHOULDER,
        mp_pose.PoseLandmark.RIGHT_SHOULDER,
        mp_pose.PoseLandmark.LEFT_HIP,
        mp_pose.PoseLandmark.RIGHT_HIP
    ]
    
    # Check visibility of required landmarks
    for landmark_idx in required_landmarks:
        if landmark_idx >= len(landmarks) or landmarks[landmark_idx].visibility < 0.5:
            return None
    
    # Calculate midpoints
    shoulder_midpoint = np.array([
        (landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x + landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x) / 2,
        (landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y + landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y) / 2
    ])
    
    hip_midpoint = np.array([
        (landmarks[mp_pose.PoseLandmark.LEFT_HIP].x + landmarks[mp_pose.PoseLandmark.RIGHT_HIP].x) / 2,
        (landmarks[mp_pose.PoseLandmark.LEFT_HIP].y + landmarks[mp_pose.PoseLandmark.RIGHT_HIP].y) / 2
    ])
    
    # Calculate spine vector and vertical vector
    spine_vector = shoulder_midpoint - hip_midpoint
    vertical_vector = np.array([0, -1])  # Up direction
    
    # Normalize vectors
    spine_vector_normalized = spine_vector / np.linalg.norm(spine_vector)
    
    # Calculate spine angle with respect to vertical
    spine_angle = math.degrees(math.acos(np.clip(np.dot(vertical_vector, spine_vector_normalized), -1.0, 1.0)))
    
    # Calculate lateral lean (left/right tilt of spine)
    lateral_lean = math.degrees(math.atan2(spine_vector[0], -spine_vector[1]))
    
    return {
        'spine_angle': spine_angle,
        'lateral_lean': lateral_lean
    }


def classify_posture_issue(metric_name, value, thresholds):
    """Classify posture issue based on metric value and thresholds."""
    if metric_name in thresholds:
        if value > thresholds[metric_name]['severe']:
            return 'severe'
        elif value > thresholds[metric_name]['moderate']:
            return 'moderate'
        elif value > thresholds[metric_name]['mild']:
            return 'mild'
    return 'normal'


def analyze_posture(video_path, calibration_seconds=3):
    """
    Analyze posture from video with enhanced accuracy and edge case handling.
    
    Args:
        video_path: Path to the video file
        calibration_seconds: Seconds at the start of the video to use for calibration
    """
    # Initialize MediaPipe Pose with optimal settings for accuracy
    mp_pose = mp.solutions.pose
    mp_drawing = mp.solutions.drawing_utils

    # Check if the video file exists
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video file not found at path: {video_path}")

    # Open video
    cap = cv2.VideoCapture(video_path)
    frame_rate = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if total_frames <= 0 or frame_rate <= 0:
        raise ValueError(f"Invalid video: {total_frames} frames at {frame_rate} FPS")
    
    # Calculate calibration frames
    calibration_frames = int(calibration_seconds * frame_rate)
    
    # Analysis tracking variables
    detected_frames = 0
    frames_with_issues = 0
    calibration_data = {
        'shoulder_tilt': [],
        'hip_tilt': [],
        'head_tilt': [],
        'forward_lean': [],
        'spine_angle': [],
        'lateral_lean': []
    }
    
    # For temporal smoothing - critical for accurate analysis
    history_length = min(30, int(frame_rate))
    metric_history = {
        'shoulder_tilt': deque(maxlen=history_length),
        'hip_tilt': deque(maxlen=history_length),
        'head_tilt': deque(maxlen=history_length),
        'forward_lean': deque(maxlen=history_length),
        'spine_angle': deque(maxlen=history_length),
        'lateral_lean': deque(maxlen=history_length)
    }
    
    # Track specific posture issues
    posture_issues = []
    frame_metrics = []
    
    # Analysis mode (full body or upper body only)
    analysis_mode = 'detecting'  # Will be set to 'full_body' or 'upper_body' after calibration
    visibility_history = []
    
    # Process video with optimal settings
    with mp_pose.Pose(
        min_detection_confidence=0.6,  # Higher confidence threshold for more reliable detections
        min_tracking_confidence=0.6,   # Higher tracking confidence for more stable tracking
        model_complexity=2,            # Maximum complexity for best accuracy
        smooth_landmarks=True          # Enable landmark smoothing for stability
    ) as pose:
        frame_count = 0
        prev_landmarks = None
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_count += 1
            
            # Skip frames if video is too long (process 3 frames per second)
            if frame_rate > 10 and frame_count % max(1, int(frame_rate / 3)) != 0:
                continue
            
            # Analyze video at a dynamic resolution based on input size
            h, w = frame.shape[:2]
            resize_factor = 1.0
            
            # Resize very large frames for better performance without compromising accuracy
            if w > 1280:
                resize_factor = 1280 / w
                new_w, new_h = int(w * resize_factor), int(h * resize_factor)
                frame = cv2.resize(frame, (new_w, new_h))
            
            # Convert frame to RGB for MediaPipe with optimal preprocessing
            image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Apply light color correction to improve landmark detection
            image = cv2.convertScaleAbs(image, alpha=1.05, beta=5)
            
            # Ensure image is contiguous for better performance
            image = np.ascontiguousarray(image)
            
            # Process the frame with MediaPipe Pose
            results = pose.process(image)
            
            if results.pose_landmarks:
                detected_frames += 1
                landmarks = results.pose_landmarks.landmark
                
                # Apply landmark continuity correction - use previous landmarks to stabilize results
                if prev_landmarks is not None:
                    for i, (curr, prev) in enumerate(zip(landmarks, prev_landmarks)):
                        if curr.visibility < 0.5 and prev.visibility > 0.7:
                            landmarks[i].x = prev.x
                            landmarks[i].y = prev.y
                            landmarks[i].z = prev.z
                            landmarks[i].visibility = prev.visibility * 0.9  # Decay visibility slightly
                
                # Store current landmarks for next frame
                prev_landmarks = landmarks.copy()
                
                # Check visibility of body parts
                visibility = calculate_visibility_score(landmarks)
                visibility_history.append(visibility)
                
                # Determine analysis mode during calibration
                if frame_count <= calibration_frames:
                    if visibility['lower_body_visible']:
                        analysis_mode = 'full_body'
                    elif visibility['upper_body_visible']:
                        analysis_mode = 'upper_body'
                
                # Extract landmarks and calculate metrics
                frame_data = {'frame': frame_count}
                
                # Get shoulder and hip landmarks if visible
                if visibility['upper_body_visible']:
                    # Get shoulder coordinates
                    left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                                    landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y]
                    right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                                      landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y]
                    
                    # Validate shoulder detection with distance checks
                    shoulder_distance = math.sqrt(
                        (right_shoulder[0] - left_shoulder[0])**2 + 
                        (right_shoulder[1] - left_shoulder[1])**2
                    )
                    
                    # Only analyze if shoulders are detected with reasonable distance
                    if 0.05 < shoulder_distance < 0.8:
                        # Calculate shoulder tilt
                        shoulder_tilt = calculate_tilt_angle(left_shoulder, right_shoulder)
                        frame_data['shoulder_tilt'] = shoulder_tilt
                        metric_history['shoulder_tilt'].append(shoulder_tilt)
                    
                    # Get head position with additional validation
                    head_metrics = calculate_head_position(landmarks, mp_pose)
                    if head_metrics:
                        if head_metrics['head_tilt'] is not None:
                            # Validate head tilt value
                            if 0 <= head_metrics['head_tilt'] < 60:  # Reasonable range check
                                frame_data['head_tilt'] = head_metrics['head_tilt']
                                metric_history['head_tilt'].append(head_metrics['head_tilt'])
                        
                        # Validate forward lean angle
                        if 0 <= head_metrics['forward_lean'] < 90:  # Reasonable range check
                            frame_data['forward_lean'] = head_metrics['forward_lean']
                            metric_history['forward_lean'].append(head_metrics['forward_lean'])
                
                # Get hip measurements if visible (full body mode)
                if visibility['lower_body_visible'] or analysis_mode == 'full_body':
                    try:
                        left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP].x,
                                   landmarks[mp_pose.PoseLandmark.LEFT_HIP].y]
                        right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP].x,
                                    landmarks[mp_pose.PoseLandmark.RIGHT_HIP].y]
                        
                        # Validate hip detection with distance checks
                        hip_distance = math.sqrt(
                            (right_hip[0] - left_hip[0])**2 + 
                            (right_hip[1] - left_hip[1])**2
                        )
                        
                        # Only analyze if hips are detected with reasonable distance
                        if 0.05 < hip_distance < 0.5:
                            # Calculate hip tilt
                            hip_tilt = calculate_tilt_angle(left_hip, right_hip)
                            frame_data['hip_tilt'] = hip_tilt
                            metric_history['hip_tilt'].append(hip_tilt)
                        
                        # Calculate spine alignment with additional validation
                        spine_metrics = calculate_spine_alignment(landmarks, mp_pose)
                        if spine_metrics:
                            # Validate spine angles
                            if 0 <= spine_metrics['spine_angle'] < 60:
                                frame_data['spine_angle'] = spine_metrics['spine_angle']
                                metric_history['spine_angle'].append(spine_metrics['spine_angle'])
                            
                            if -30 <= spine_metrics['lateral_lean'] <= 30:
                                frame_data['lateral_lean'] = spine_metrics['lateral_lean']
                                metric_history['lateral_lean'].append(spine_metrics['lateral_lean'])
                    except (IndexError, AttributeError):
                        # Handle case where landmarks might be detected but not accurate
                        pass
                
                # Store frame metrics if we have valid measurements
                if len(frame_data) > 1:  # More than just the frame number
                    frame_metrics.append(frame_data)
                
                # For calibration phase, collect baseline metrics
                if frame_count <= calibration_frames:
                    for key, value in frame_data.items():
                        if key in calibration_data and key != 'frame':
                            calibration_data[key].append(value)
                else:
                    # After calibration, evaluate posture using adaptive thresholds
                    frame_issues = []
                    
                    # Calculate adaptive thresholds based on calibration data
                    thresholds = {}
                    for metric, values in calibration_data.items():
                        if values:  # If we have calibration data for this metric
                            # Calculate robust statistics using percentiles instead of mean/std
                            baseline = np.median(values)
                            variance = np.percentile(values, 75) - np.percentile(values, 25)
                            variance = max(variance, 1.0)  # Ensure minimum variance
                            
                            thresholds[metric] = {
                                'mild': baseline + 1.0 * variance,
                                'moderate': baseline + 1.5 * variance,
                                'severe': baseline + 2.0 * variance
                            }
                    
                    # Define default thresholds for metrics without calibration data
                    default_thresholds = {
                        'shoulder_tilt': {'mild': 5, 'moderate': 10, 'severe': 15},
                        'hip_tilt': {'mild': 5, 'moderate': 10, 'severe': 15},
                        'head_tilt': {'mild': 10, 'moderate': 20, 'severe': 30},
                        'forward_lean': {'mild': 15, 'moderate': 25, 'severe': 35},
                        'spine_angle': {'mild': 10, 'moderate': 20, 'severe': 30},
                        'lateral_lean': {'mild': 5, 'moderate': 10, 'severe': 15}
                    }
                    
                    # Apply advanced temporal smoothing to metrics using weighted median filter
                    smoothed_metrics = {}
                    for metric, history in metric_history.items():
                        if len(history) >= 5:  # Need at least 5 points for robust smoothing
                            recent_values = list(history)[-9:]  # Last 9 values
                            # Apply weighted median filter with more weight to recent values
                            weights = [1, 1, 1, 2, 2, 3, 3, 4, 5][-len(recent_values):]
                            weighted_values = []
                            for val, weight in zip(recent_values, weights):
                                weighted_values.extend([val] * weight)
                            smoothed_metrics[metric] = np.median(weighted_values)
                    
                    # Detect posture issues using smoothed metrics and adaptive thresholds
                    for metric, value in smoothed_metrics.items():
                        metric_thresholds = thresholds.get(metric, default_thresholds.get(metric, {}))
                        severity = classify_posture_issue(metric, value, {'dummy': metric_thresholds})
                        
                        if severity != 'normal':
                            issue_description = ''
                            if metric == 'shoulder_tilt' and value > metric_thresholds['mild']:
                                issue_description = f"Uneven shoulders ({severity})"
                            elif metric == 'hip_tilt' and value > metric_thresholds['mild']:
                                issue_description = f"Uneven hips ({severity})"
                            elif metric == 'head_tilt' and value > metric_thresholds['mild']:
                                issue_description = f"Tilted head ({severity})"
                            elif metric == 'forward_lean' and value > metric_thresholds['mild']:
                                issue_description = f"Forward head posture ({severity})"
                            elif metric == 'spine_angle' and value > metric_thresholds['mild']:
                                issue_description = f"Poor spine alignment ({severity})"
                            elif metric == 'lateral_lean' and value > metric_thresholds['mild']:
                                issue_description = f"Lateral lean ({severity})"
                            
                            if issue_description:
                                frame_issues.append(issue_description)
                    
                    if frame_issues:
                        frames_with_issues += 1
                        for issue in frame_issues:
                            posture_issues.append(issue)

    # Release video capture
    cap.release()
    
    # Process collected data
    posture_analysis = {}
    
    # Calculate detection confidence
    detection_rate = (detected_frames / frame_count) * 100 if frame_count > 0 else 0
    
    # Generate comprehensive posture analysis
    if detected_frames > 10:  # Need at least 10 detected frames for reliable analysis
        # Determine analysis mode from visibility history
        if analysis_mode == 'detecting':
            upper_body_visible_count = sum(1 for v in visibility_history if v['upper_body_visible'])
            lower_body_visible_count = sum(1 for v in visibility_history if v['lower_body_visible'])
            
            if lower_body_visible_count > len(visibility_history) * 0.3:
                analysis_mode = 'full_body'
            elif upper_body_visible_count > len(visibility_history) * 0.3:
                analysis_mode = 'upper_body'
            else:
                analysis_mode = 'limited'
        
        # Calculate reliable poor posture percentage
        valid_frames = max(1, detected_frames - calibration_frames)  # Exclude calibration frames
        poor_posture_percentage = (frames_with_issues / valid_frames) * 100 if valid_frames > 0 else 0
        
        # Count occurrences of each posture issue with confidence weighting
        issue_counts = {}
        for issue in posture_issues:
            issue_name = issue.split('(')[0].strip()
            severity = issue.split('(')[1].split(')')[0] if '(' in issue else 'mild'
            
            # Weight by severity
            severity_weight = {'mild': 1, 'moderate': 2, 'severe': 3}.get(severity, 1)
            
            if issue_name in issue_counts:
                issue_counts[issue_name] += severity_weight
            else:
                issue_counts[issue_name] = severity_weight
        
        # Sort issues by weighted frequency
        sorted_issues = sorted(issue_counts.items(), key=lambda x: x[1], reverse=True)
        
        # Normalize issue frequencies relative to detection count and severity
        total_weights = sum(count for _, count in sorted_issues)
        main_issues = []
        
        if total_weights > 0:
            for issue, count in sorted_issues:
                # Calculate frequency as percentage of detected frames
                frequency = (count / total_weights) * poor_posture_percentage
                
                # Only include issues with significant frequency (> 5%)
                if frequency > 5:
                    main_issues.append({"issue": issue, "frequency": frequency})
        
        # Calculate aggregate metrics across the video with outlier removal
        aggregate_metrics = {}
        for metric in calibration_data.keys():
            metric_values = [frame.get(metric) for frame in frame_metrics if metric in frame]
            if metric_values and len(metric_values) > 5:
                # Filter outliers
                q1 = np.percentile(metric_values, 25)
                q3 = np.percentile(metric_values, 75)
                iqr = q3 - q1
                lower_bound = q1 - 1.5 * iqr
                upper_bound = q3 + 1.5 * iqr
                filtered_values = [v for v in metric_values if lower_bound <= v <= upper_bound]
                
                if filtered_values:
                    aggregate_metrics[metric] = {
                        'mean': np.mean(filtered_values),
                        'median': np.median(filtered_values),
                        'std': np.std(filtered_values),
                        'min': min(filtered_values),
                        'max': max(filtered_values),
                        'p25': np.percentile(filtered_values, 25),  # 25th percentile
                        'p75': np.percentile(filtered_values, 75)   # 75th percentile
                    }
        
        posture_analysis = {
            'detected_frames': detected_frames,
            'detection_rate': detection_rate,
            'analysis_mode': analysis_mode,
            'frames_with_issues': frames_with_issues,
            'poor_posture_percentage': poor_posture_percentage,
            'main_issues': main_issues,
            'aggregate_metrics': aggregate_metrics,
            'frame_metrics': frame_metrics  # Include frame-by-frame data
        }
    else:
        posture_analysis = {
            'detected_frames': detected_frames,
            'detection_rate': detection_rate,
            'analysis_mode': 'failed',
            'frames_with_issues': 0,
            'poor_posture_percentage': 0,
            'main_issues': [],
            'aggregate_metrics': {},
            'error': "Insufficient pose detection. Please ensure face and upper body are clearly visible."
        }
    
    return posture_analysis


def generate_posture_report(video_path, report_id):
    """
    Generate a detailed posture analysis report with enhanced accuracy.
    
    Args:
        video_path: Path to the video file
        report_id: ID for the report
    """
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video file not found at path: {video_path}")

    # Analyze posture with enhanced system
    analysis_results = analyze_posture(video_path)

    # Add facial expression and eye contact analysis
    try:
        from services.facial_analysis_service import analyze_facial_engagement
        facial_results = analyze_facial_engagement(video_path)
        analysis_results["facial_analysis"] = facial_results
    except Exception as e:
        print(f"Warning: Facial analysis failed: {str(e)}")
        analysis_results["facial_analysis"] = {"error": str(e)}

    # Generate timestamp for report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_filename = f"res/report/{report_id}_body.txt"

    # Calculate body language score (1-10 scale)
    posture_score = 0
    facial_score = 0
    
    if analysis_results['detected_frames'] > 0:
        # Base score starts at 100 and gets reduced for poor posture
        base_score = max(0, min(100, 100 - analysis_results['poor_posture_percentage']))
        
        # Further adjust based on severity and variety of issues
        issue_penalty = min(30, len(analysis_results['main_issues']) * 5)
        base_score = max(0, base_score - issue_penalty)
        
        # Convert from 0-100 scale to 1-10 scale (posture component)
        posture_score = max(1, min(10, round(base_score / 10)))
    
    # Calculate facial engagement component (if available)
    if "facial_analysis" in analysis_results and "error" not in analysis_results["facial_analysis"]:
        facial_data = analysis_results["facial_analysis"]
        engagement_score = facial_data.get("engagement_metrics", {}).get("average", 0)
        eye_contact_score = facial_data.get("eye_contact_ratio", 0)
        
        # Weight engagement and eye contact equally
        facial_base_score = (engagement_score + eye_contact_score) / 2
        
        # Convert to 1-10 scale
        facial_score = max(1, min(10, round(facial_base_score / 10)))
    
    # Final body language score: 70% posture, 30% facial expression
    final_score = posture_score * 0.7 + facial_score * 0.3 if facial_score > 0 else posture_score
    final_score = max(1, min(10, round(final_score)))

    # Prepare issues for database in the required format
    weakness_topics = []
    
    # Add posture issues
    for issue in analysis_results['main_issues']:
        issue_name = issue['issue']
        frequency = issue['frequency']
        
        # Skip if less than 10% frequency
        if frequency < 10:
            continue
            
        # Create topic object with required properties
        topic_obj = {
            "topic": issue_name,
            "examples": [],  # Will be populated with specific examples
            "suggestions": []  # Will be populated with appropriate suggestions
        }
        
        # Add specific examples based on issue type
        if "Uneven shoulders" in issue_name:
            topic_obj["examples"] = [
                "Shoulders not level during presentation",
                f"Right/left shoulder higher for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice shoulder alignment exercises to improve posture. Be mindful of keeping shoulders level during presentations. Consider ergonomic adjustments to your workspace to promote better shoulder alignment."
            ]
        elif "Uneven hips" in issue_name:
            topic_obj["examples"] = [
                "Shifting weight to one side",
                f"Uneven hip alignment for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice standing with weight evenly distributed on both feet. Consider exercises that strengthen core and hip stabilizers for better balance. Be mindful of keeping your hips level while standing during presentations."
            ]
        elif "Tilted head" in issue_name:
            topic_obj["examples"] = [
                "Head tilted to one side",
                f"Head not level for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice maintaining a neutral head position in front of a mirror. Be conscious of keeping your eyes level when speaking. Regular neck stretching and strengthening exercises can help improve head alignment during presentations."
            ]
        elif "Forward head" in issue_name:
            topic_obj["examples"] = [
                "Chin jutting forward",
                f"Forward head posture for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice chin tucks to improve neck alignment. Strengthen upper back muscles to support proper head position. Be mindful of keeping your ears aligned with your shoulders during presentations."
            ]
        elif "Poor spine" in issue_name:
            topic_obj["examples"] = [
                "Slouching during presentation",
                f"Spine not properly aligned for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice standing tall with shoulders back and spine in neutral alignment. Strengthen core muscles to support better posture. Take regular breaks during long presentations to reset your posture and reduce fatigue."
            ]
        elif "Lateral lean" in issue_name:
            topic_obj["examples"] = [
                "Leaning to one side",
                f"Body tilted laterally for {frequency:.1f}% of presentation"
            ]
            topic_obj["suggestions"] = [
                "Practice standing in front of a mirror to observe and correct your alignment. Strengthen core muscles for better stability and balance. Be conscious of distributing your weight evenly across both feet while presenting."
            ]
        
        weakness_topics.append(topic_obj)
    
    # Add facial expression and eye contact issues
    if "facial_analysis" in analysis_results and "facial_issues" in analysis_results["facial_analysis"]:
        for issue in analysis_results["facial_analysis"]["facial_issues"]:
            topic_obj = {
                "topic": issue["issue"],
                "examples": [],
                "suggestions": issue["suggestions"]
            }
            
            # Add specific examples based on issue type
            if "Low facial engagement" in issue["issue"]:
                topic_obj["examples"] = [
                    "Limited variation in facial expressions",
                    "Minimal emotional display during presentation"
                ]
            elif "Insufficient eye contact" in issue["issue"]:
                topic_obj["examples"] = [
                    "Looking away from camera/audience frequently",
                    "Eyes focused downward or to the side"
                ]
            elif "Overly serious" in issue["issue"]:
                topic_obj["examples"] = [
                    "Consistently serious facial expression",
                    "Few or no smiles during presentation"
                ]
            
            weakness_topics.append(topic_obj)
    
    # Add hand gesture feedback
    if 'gesture_metrics' in analysis_results and analysis_results['gesture_metrics']:
        gesture_data = analysis_results['gesture_metrics']
        
        # Check for limited gesture space
        if gesture_data['avg_extension'] < 0.15:  # Small gesture space
            topic_obj = {
                "topic": "Limited Gesture Space",
                "examples": [
                    "Hands kept close to body",
                    "Small, constrained hand movements"
                ],
                "suggestions": [
                    "Try to expand your gestures to appear more confident and engaging. Practice using more of the space around you with purposeful hand movements that emphasize key points. Avoid keeping your hands too close to your body, which can signal nervousness or hesitation."
                ]
            }
            weakness_topics.append(topic_obj)
            
        # Check for overactive gestures
        if gesture_data['movement_frequency'] > 0.8:  # Very frequent movements
            topic_obj = {
                "topic": "Excessive Hand Movements",
                "examples": [
                    "Constant hand gestures throughout presentation",
                    "Distracting frequent movements"
                ],
                "suggestions": [
                    "Consider using more deliberate, purposeful gestures. While hand movements help engage your audience, too many can become distracting. Focus on using gestures to emphasize important points rather than moving constantly. Practice pausing with hands in a neutral, resting position."
                ]
            }
            weakness_topics.append(topic_obj)
    
    # Add movement pattern feedback
    if 'movement_metrics' in analysis_results and analysis_results['movement_metrics']:
        movement_data = analysis_results['movement_metrics']
        
        if movement_data['movement_pattern'] == 'pacing':
            topic_obj = {
                "topic": "Repetitive Pacing",
                "examples": [
                    "Moving back and forth in predictable pattern",
                    "Rhythmic pacing across presentation area"
                ],
                "suggestions": [
                    "Try to vary your movement patterns to appear more natural and deliberate. Pacing can signal nervousness to your audience. Instead, move with purpose – stand still when making important points, and move deliberately to transition between topics or engage different sections of your audience."
                ]
            }
            weakness_topics.append(topic_obj)
    
    # Save data to Supabase
    try:
        from services import storage_service
        
        # Update only body language fields
        update_data = {
            "scoreBodyLanguage": final_score,  # Now on a 1-10 scale
            "weaknessTopicsBodylan": weakness_topics
        }
        
        storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
    except Exception as e:
        print(f"Warning: Failed to update database: {e}")

    # Write detailed report to file
    with open(report_filename, 'w') as report_file:
        report_file.write("Body Language and Facial Engagement Analysis Report\n")
        report_file.write("===============================================\n\n")
        report_file.write(f"Video Analyzed: {video_path}\n")
        report_file.write(f"Analysis Timestamp: {timestamp}\n\n")
        
        # Posture section
        report_file.write("POSTURE ANALYSIS\n")
        report_file.write("---------------\n")
        report_file.write(f"Analysis Mode: {analysis_results['analysis_mode']}\n")
        report_file.write(f"Frames with Pose Detected: {analysis_results['detected_frames']} ")
        report_file.write(f"({analysis_results['detection_rate']:.1f}% of video)\n")
        report_file.write(f"Poor Posture Percentage: {analysis_results['poor_posture_percentage']:.2f}%\n")
        report_file.write(f"Posture Score Component: {posture_score}/10\n\n")
        
        report_file.write("Main Posture Issues Detected:\n")
        if analysis_results['main_issues']:
            for idx, issue in enumerate(analysis_results['main_issues'], 1):
                report_file.write(f"{idx}. {issue['issue']} - Present in {issue['frequency']:.1f}% of frames\n")
        else:
            report_file.write("No significant posture issues detected.\n")
        
        # Facial expression section
        if "facial_analysis" in analysis_results and "error" not in analysis_results["facial_analysis"]:
            facial_data = analysis_results["facial_analysis"]
            
            report_file.write("\nFACIAL EXPRESSION & EYE CONTACT ANALYSIS\n")
            report_file.write("-----------------------------------\n")
            report_file.write(f"Face Detection Rate: {facial_data['detection_rate']:.1f}%\n")
            report_file.write(f"Average Engagement Level: {facial_data['engagement_metrics']['average']:.1f}%\n")
            report_file.write(f"Eye Contact Quality: {facial_data['eye_contact_ratio']:.1f}%\n")
            report_file.write(f"Dominant Expression: {facial_data['dominant_expression'].title()}\n")
            report_file.write(f"Facial Score Component: {facial_score}/10\n\n")
            
            report_file.write("Expression Distribution:\n")
            for expr, percentage in facial_data['expression_distribution'].items():
                if percentage > 0:
                    report_file.write(f"- {expr.title()}: {percentage:.1f}%\n")
            
            if facial_data["facial_issues"]:
                report_file.write("\nFacial Engagement Issues:\n")
                for idx, issue in enumerate(facial_data["facial_issues"], 1):
                    report_file.write(f"{idx}. {issue['issue']}\n")
                    report_file.write(f"   Suggestion: {issue['suggestions'][0]}\n")
        
        # Combined score
        report_file.write(f"\nOVERALL BODY LANGUAGE SCORE: {final_score}/10\n")
        
        # Recommendations
        report_file.write("\nRecommendations:\n")
        for issue in weakness_topics:
            report_file.write(f"  * {issue['topic']}: {issue['suggestions'][0]}\n")
            
        if analysis_results['analysis_mode'] == 'upper_body':
            report_file.write("\nNote: Posture analysis performed on upper body only as lower body was not visible in the video.\n")

    print(f"Comprehensive body language analysis report saved as {report_filename}")
    return report_filename
