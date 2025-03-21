import cv2
import mediapipe as mp
import numpy as np
import os
import math
import argparse
import time
from services.pose_analysis_service import (
    calculate_tilt_angle,
    calculate_visibility_score,
    calculate_head_position,
    calculate_spine_alignment
)

def validate_pose_detection(video_path, output_folder=None, save_frames=False):
    """
    Validate MediaPipe pose detection by visualizing landmarks and measurements.
    
    Args:
        video_path: Path to the test video
        output_folder: Where to save visualization frames (if save_frames=True)
        save_frames: Whether to save frames with visualization
    """
    # Initialize MediaPipe Pose
    mp_pose = mp.solutions.pose
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    # Check if video exists
    if not os.path.exists(video_path):
        print(f"Error: Video file not found at path: {video_path}")
        return
    
    # Create output directory if needed
    if save_frames and output_folder:
        os.makedirs(output_folder, exist_ok=True)
        
    # Open video
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    detection_stats = {'detected': 0, 'missed': 0, 'upper_body_only': 0, 'full_body': 0}
    angle_records = []
    
    # For analyzing visibility patterns
    visibility_patterns = {
        'upper_body': 0,
        'lower_body': 0,
        'face': 0
    }
    
    with mp_pose.Pose(
        min_detection_confidence=0.5, 
        min_tracking_confidence=0.5,
        model_complexity=1
    ) as pose:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_count += 1
            
            # Convert to RGB for MediaPipe
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image_rgb = np.ascontiguousarray(image_rgb)
            
            # Process with MediaPipe
            start_time = time.time()
            results = pose.process(image_rgb)
            process_time = (time.time() - start_time) * 1000  # ms
            
            # For visualization
            annotated_frame = frame.copy()
            
            if results.pose_landmarks:
                detection_stats['detected'] += 1
                
                # Draw pose landmarks
                mp_drawing.draw_landmarks(
                    annotated_frame,
                    results.pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style()
                )
                
                # Extract landmarks
                landmarks = results.pose_landmarks.landmark
                
                # Check visibility of body parts
                visibility = calculate_visibility_score(landmarks)
                if visibility['upper_body_visible']:
                    visibility_patterns['upper_body'] += 1
                if visibility['lower_body_visible']:
                    visibility_patterns['lower_body'] += 1
                if visibility['face_visible']:
                    visibility_patterns['face'] += 1
                    
                # Count analysis modes
                if visibility['lower_body_visible']:
                    detection_stats['full_body'] += 1
                elif visibility['upper_body_visible']:
                    detection_stats['upper_body_only'] += 1
                
                # Create frame record
                frame_record = {'frame': frame_count}
                
                # Get shoulder measurements
                if visibility['upper_body_visible']:
                    left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                                    landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y]
                    right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                                    landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y]
                    
                    # Calculate shoulder tilt
                    shoulder_tilt = calculate_tilt_angle(left_shoulder, right_shoulder)
                    frame_record['shoulder_tilt'] = shoulder_tilt
                    
                    # Add to frame
                    cv2.putText(
                        annotated_frame, 
                        f"Shoulder tilt: {shoulder_tilt:.1f}°", 
                        (10, 30), 
                        cv2.FONT_HERSHEY_SIMPLEX, 
                        0.7, 
                        (0, 255, 0), 
                        2
                    )
                    
                    # Calculate head position
                    head_metrics = calculate_head_position(landmarks, mp_pose)
                    if head_metrics:
                        if head_metrics['head_tilt'] is not None:
                            frame_record['head_tilt'] = head_metrics['head_tilt']
                            cv2.putText(
                                annotated_frame, 
                                f"Head tilt: {head_metrics['head_tilt']:.1f}°", 
                                (10, 60), 
                                cv2.FONT_HERSHEY_SIMPLEX, 
                                0.7, 
                                (0, 255, 0), 
                                2
                            )
                        
                        frame_record['forward_lean'] = head_metrics['forward_lean']
                        cv2.putText(
                            annotated_frame, 
                            f"Forward lean: {head_metrics['forward_lean']:.1f}°", 
                            (10, 90), 
                            cv2.FONT_HERSHEY_SIMPLEX, 
                            0.7, 
                            (0, 255, 0), 
                            2
                        )
                
                # Hip and spine measurements if lower body is visible
                if visibility['lower_body_visible']:
                    left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP].x,
                               landmarks[mp_pose.PoseLandmark.LEFT_HIP].y]
                    right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP].x,
                                landmarks[mp_pose.PoseLandmark.RIGHT_HIP].y]
                    
                    # Calculate hip tilt
                    hip_tilt = calculate_tilt_angle(left_hip, right_hip)
                    frame_record['hip_tilt'] = hip_tilt
                    
                    # Add to frame
                    cv2.putText(
                        annotated_frame, 
                        f"Hip tilt: {hip_tilt:.1f}°", 
                        (10, 120), 
                        cv2.FONT_HERSHEY_SIMPLEX, 
                        0.7, 
                        (0, 255, 0), 
                        2
                    )
                    
                    # Calculate spine alignment
                    spine_metrics = calculate_spine_alignment(landmarks, mp_pose)
                    if spine_metrics:
                        frame_record['spine_angle'] = spine_metrics['spine_angle']
                        frame_record['lateral_lean'] = spine_metrics['lateral_lean']
                        
                        # Add to frame
                        cv2.putText(
                            annotated_frame, 
                            f"Spine angle: {spine_metrics['spine_angle']:.1f}°", 
                            (10, 150), 
                            cv2.FONT_HERSHEY_SIMPLEX, 
                            0.7, 
                            (0, 255, 0), 
                            2
                        )
                        
                        cv2.putText(
                            annotated_frame, 
                            f"Lateral lean: {spine_metrics['lateral_lean']:.1f}°", 
                            (10, 180), 
                            cv2.FONT_HERSHEY_SIMPLEX, 
                            0.7, 
                            (0, 255, 0), 
                            2
                        )
                
                # Store all metrics for this frame
                angle_records.append(frame_record)
                
                # Add visibility indicators
                y_pos = annotated_frame.shape[0] - 120
                cv2.putText(
                    annotated_frame, 
                    f"Upper body visible: {visibility['upper_body_visible']}", 
                    (10, y_pos), 
                    cv2.FONT_HERSHEY_SIMPLEX, 
                    0.7, 
                    (0, 255, 0) if visibility['upper_body_visible'] else (0, 0, 255), 
                    2
                )
                
                y_pos += 30
                cv2.putText(
                    annotated_frame, 
                    f"Lower body visible: {visibility['lower_body_visible']}", 
                    (10, y_pos), 
                    cv2.FONT_HERSHEY_SIMPLEX, 
                    0.7, 
                    (0, 255, 0) if visibility['lower_body_visible'] else (0, 0, 255), 
                    2
                )
                
                y_pos += 30
                cv2.putText(
                    annotated_frame, 
                    f"Face visible: {visibility['face_visible']}", 
                    (10, y_pos), 
                    cv2.FONT_HERSHEY_SIMPLEX, 
                    0.7, 
                    (0, 255, 0) if visibility['face_visible'] else (0, 0, 255), 
                    2
                )
            else:
                detection_stats['missed'] += 1
                cv2.putText(
                    annotated_frame, 
                    "No pose detected", 
                    (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 
                    0.7, 
                    (0, 0, 255), 
                    2
                )
            
            # Add processing time at the bottom
            cv2.putText(
                annotated_frame, 
                f"Process time: {process_time:.1f} ms", 
                (10, annotated_frame.shape[0] - 30), 
                cv2.FONT_HERSHEY_SIMPLEX, 
                0.7, 
                (255, 0, 0), 
                2
            )
            
            # Display frame
            cv2.imshow('MediaPipe Pose Validation', annotated_frame)
            
            # Save frame if requested
            if save_frames and output_folder:
                cv2.imwrite(f"{output_folder}/frame_{frame_count:04d}.jpg", annotated_frame)
            
            # Break on ESC key
            if cv2.waitKey(5) & 0xFF == 27:
                break
    
    # Release resources
    cap.release()
    cv2.destroyAllWindows()
    
    # Calculate statistics
    detection_rate = detection_stats['detected'] / frame_count * 100 if frame_count > 0 else 0
    upper_body_rate = detection_stats['upper_body_only'] / detection_stats['detected'] * 100 if detection_stats['detected'] > 0 else 0
    full_body_rate = detection_stats['full_body'] / detection_stats['detected'] * 100 if detection_stats['detected'] > 0 else 0
    
    # Print validation summary
    print("\n=== MediaPipe Enhanced Pose Detection Validation ===")
    print(f"Video: {video_path}")
    print(f"Total frames: {frame_count}")
    print(f"Frames with pose detected: {detection_stats['detected']} ({detection_rate:.1f}%)")
    print(f"Frames without pose detected: {detection_stats['missed']}")
    print(f"Upper body only: {detection_stats['upper_body_only']} frames ({upper_body_rate:.1f}%)")
    print(f"Full body: {detection_stats['full_body']} frames ({full_body_rate:.1f}%)")
    
    # Visibility statistics
    print("\nVisibility Statistics:")
    for part, count in visibility_patterns.items():
        percentage = count / detection_stats['detected'] * 100 if detection_stats['detected'] > 0 else 0
        print(f"{part.replace('_', ' ').title()}: {count} frames ({percentage:.1f}%)")
    
    # Process angle records to get statistics for each metric
    if angle_records:
        print("\nAngle Measurements:")
        
        # Collect all metrics
        metrics = {}
        for record in angle_records:
            for key, value in record.items():
                if key != 'frame':
                    if key not in metrics:
                        metrics[key] = []
                    metrics[key].append(value)
        
        # Print statistics for each metric
        for metric_name, values in metrics.items():
            if values:
                print(f"{metric_name.replace('_', ' ').title()}:")
                print(f"  Avg: {np.mean(values):.2f}°")
                print(f"  Min: {min(values):.2f}°")
                print(f"  Max: {max(values):.2f}°")
                print(f"  Std Dev: {np.std(values):.2f}°")
    
    return {
        'detection_rate': detection_rate,
        'angle_records': angle_records,
        'detection_stats': detection_stats,
        'visibility_patterns': visibility_patterns
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Validate MediaPipe pose detection.')
    parser.add_argument('--video', type=str, required=True, help='Path to input video file')
    parser.add_argument('--output', type=str, help='Path to output folder for frames')
    parser.add_argument('--save', action='store_true', help='Save frames with visualization')
    
    args = parser.parse_args()
    
    validate_pose_detection(args.video, args.output, args.save)
