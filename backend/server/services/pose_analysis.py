import cv2
import mediapipe as mp
import numpy as np
import math
from datetime import datetime


def calculate_tilt_angle(point1, point2):
    """Calculate the tilt angle between two points relative to the horizontal axis."""
    dx = point2[0] - point1[0]
    dy = point2[1] - point1[1]
    angle = math.degrees(math.atan2(dy, dx))
    return abs(angle)


def analyze_posture(video_path):
    # Initialize MediaPipe Pose
    mp_pose = mp.solutions.pose
    mp_drawing = mp.solutions.drawing_utils

    # Open video
    cap = cv2.VideoCapture(video_path)

    # Posture tracking variables
    poor_posture_frames = 0
    detected_frames = 0
    posture_issues = []

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Convert frame to RGB and make it contiguous in memory
            image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image = np.ascontiguousarray(image)

            # Detect pose
            results = pose.process(image)

            if results.pose_landmarks:
                detected_frames += 1

                # Extract landmarks
                landmarks = results.pose_landmarks.landmark

                # Get shoulder and hip landmarks
                left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                                 landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y]
                right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                                  landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y]
                left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP].x,
                            landmarks[mp_pose.PoseLandmark.LEFT_HIP].y]
                right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP].x,
                             landmarks[mp_pose.PoseLandmark.RIGHT_HIP].y]
                left_knee = [landmarks[mp_pose.PoseLandmark.LEFT_KNEE].x,
                             landmarks[mp_pose.PoseLandmark.LEFT_KNEE].y]
                right_knee = [landmarks[mp_pose.PoseLandmark.RIGHT_KNEE].x,
                              landmarks[mp_pose.PoseLandmark.RIGHT_KNEE].y]

                # Calculate tilt angles
                shoulder_tilt = calculate_tilt_angle(left_shoulder, right_shoulder)
                hip_tilt = calculate_tilt_angle(left_hip, right_hip)

                # Detect poor posture conditions (threshold set to 10 degrees)
                if shoulder_tilt > 10 or hip_tilt > 10:
                    poor_posture_frames += 1

                    # Track specific posture issues
                    if shoulder_tilt > 10:
                        posture_issues.append("Uneven shoulders")
                    if hip_tilt > 10:
                        posture_issues.append("Misaligned hips")

    # Release video capture
    cap.release()

    # Generate report
    poor_posture_percentage = (poor_posture_frames / detected_frames) * 100 if detected_frames > 0 else 0

    return {
        'detected_frames': detected_frames,
        'poor_posture_frames': poor_posture_frames,
        'poor_posture_percentage': poor_posture_percentage,
        'posture_issues': list(set(posture_issues))
    }


def generate_posture_report(video_path):
    # Analyze posture
    analysis_results = analyze_posture(video_path)

    # Generate timestamp for report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_filename = f"res/report/posture_analysis_report_{timestamp}.txt"

    # Write report
    with open(report_filename, 'w') as report_file:
        report_file.write("Body Language Posture Analysis Report\n")
        report_file.write("======================================\n\n")
        report_file.write(f"Video Analyzed: {video_path}\n")
        report_file.write(f"Analysis Timestamp: {timestamp}\n\n")
        report_file.write(f"Frames with Pose Detected: {analysis_results['detected_frames']}\n")
        report_file.write(f"Poor Posture Frames: {analysis_results['poor_posture_frames']}\n")
        report_file.write(f"Poor Posture Percentage: {analysis_results['poor_posture_percentage']:.2f}%\n\n")

        report_file.write("Posture Issues Detected:\n")
        for issue in analysis_results['posture_issues']:
            report_file.write(f"- {issue}\n")

        # Recommendations
        report_file.write("\nRecommendations:\n")
        if analysis_results['poor_posture_percentage'] > 30:
            report_file.write("- Significant posture issues detected. Consider consulting a physiotherapist.\n")
            report_file.write("- Practice core strengthening and alignment exercises.\n")
        elif analysis_results['poor_posture_percentage'] > 10:
            report_file.write("- Some posture inconsistencies observed. Recommended improvements:\n")
            report_file.write("  * Regular stretching\n")
            report_file.write("  * Ergonomic workspace setup\n")
        else:
            report_file.write("- Generally good posture maintained.\n")

    print(f"Posture analysis report saved as {report_filename}")
    return report_filename

# Example usage
generate_posture_report('video.mp4')
