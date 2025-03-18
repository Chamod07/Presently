import os
import cv2
import argparse
import matplotlib.pyplot as plt
import numpy as np
import json
from datetime import datetime
from services.pose_analysis_service import analyze_posture, calculate_visibility_score, calculate_head_position, calculate_spine_alignment
import mediapipe as mp

def test_pose_analysis(video_path, output_folder="pose_analysis_test", save_frames=False):
    """
    Test the pose analysis on a video and generate visualization of results.
    
    Args:
        video_path: Path to the video file
        output_folder: Folder to store visualizations and reports
        save_frames: Whether to save annotated frames
    """
    print(f"Testing pose analysis on video: {video_path}")
    
    # Create output folder
    os.makedirs(output_folder, exist_ok=True)
    
    # Run analysis
    try:
        results = analyze_posture(video_path)
        
        # Save raw results to JSON file
        with open(f"{output_folder}/analysis_results.json", "w") as f:
            json_data = {k: v for k, v in results.items() if k != 'aggregate_metrics'}
            # Convert metrics to serializable format
            if 'aggregate_metrics' in results:
                json_data['aggregate_metrics'] = {}
                for metric, values in results['aggregate_metrics'].items():
                    json_data['aggregate_metrics'][metric] = {
                        k: float(v) for k, v in values.items()
                    }
            json.dump(json_data, f, indent=2)
        
        # Save human-readable report
        with open(f"{output_folder}/analysis_report.txt", "w") as f:
            f.write("Pose Analysis Results\n")
            f.write("====================\n\n")
            
            f.write(f"Detection rate: {results['detection_rate']:.1f}%\n")
            f.write(f"Analysis mode: {results['analysis_mode']}\n")
            f.write(f"Poor posture percentage: {results['poor_posture_percentage']:.1f}%\n")
            f.write(f"Frames with issues: {results['frames_with_issues']}\n\n")
            
            f.write("Main issues:\n")
            for issue in results['main_issues']:
                f.write(f"- {issue['issue']}: {issue['frequency']:.1f}%\n")
                
            # Add detailed metrics
            if 'aggregate_metrics' in results and results['aggregate_metrics']:
                f.write("\nDetailed Measurements:\n")
                for metric, values in results['aggregate_metrics'].items():
                    readable_name = metric.replace('_', ' ').title()
                    f.write(f"{readable_name}: ")
                    f.write(f"Mean={values['mean']:.1f}°, ")
                    f.write(f"Median={values['median']:.1f}°, ")
                    f.write(f"Min={values['min']:.1f}°, ")
                    f.write(f"Max={values['max']:.1f}°, ")
                    f.write(f"StdDev={values['std']:.1f}°\n")
        
        # Create visualizations
        if 'aggregate_metrics' in results and results['aggregate_metrics']:
            metrics = results['aggregate_metrics']
            metric_names = list(metrics.keys())
            
            # Plot metrics side by side
            plt.figure(figsize=(15, 8))
            
            # Plot means with standard deviations
            means = [metrics[m]['mean'] for m in metric_names]
            stds = [metrics[m]['std'] for m in metric_names]
            
            plt.bar(range(len(metric_names)), means, yerr=stds, 
                   align='center', alpha=0.7, ecolor='black', capsize=10)
            plt.xticks(range(len(metric_names)), [m.replace('_', ' ').title() for m in metric_names], rotation=45)
            plt.ylabel('Degrees')
            plt.title('Posture Metrics with Standard Deviation')
            plt.tight_layout()
            plt.savefig(f"{output_folder}/posture_metrics.png")
            plt.close()
            
            # Pie chart for detected issues
            if results['main_issues']:
                issues = [issue['issue'] for issue in results['main_issues']]
                frequencies = [issue['frequency'] for issue in results['main_issues']]
                
                plt.figure(figsize=(10, 8))
                plt.pie(frequencies, labels=issues, autopct='%1.1f%%', startangle=90)
                plt.axis('equal')
                plt.title('Distribution of Detected Posture Issues')
                plt.tight_layout()
                plt.savefig(f"{output_folder}/issue_distribution.png")
                plt.close()
        
        # If save_frames is True, create annotated video frames
        if save_frames:
            generate_annotated_frames(video_path, output_folder)
        
        print(f"Analysis complete. Results saved to {output_folder}/")
        return results
        
    except Exception as e:
        print(f"Error during pose analysis testing: {str(e)}")
        raise

def generate_annotated_frames(video_path, output_folder):
    """Generate annotated frames with pose landmarks and metrics."""
    # Create frames subfolder
    frames_folder = os.path.join(output_folder, "frames")
    os.makedirs(frames_folder, exist_ok=True)
    
    # Initialize MediaPipe
    mp_pose = mp.solutions.pose
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    
    # Process video
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
            if frame_count % 10 != 0:  # Save every 10th frame to reduce storage
                continue
                
            # Convert to RGB
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image_rgb = np.ascontiguousarray(image_rgb)
            
            # Process with MediaPipe
            results = pose.process(image_rgb)
            
            # Create annotated frame
            annotated_frame = frame.copy()
            
            # Draw pose landmarks
            if results.pose_landmarks:
                mp_drawing.draw_landmarks(
                    annotated_frame,
                    results.pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    landmark_drawing_spec=mp_drawing_styles.get_default_pose_landmarks_style()
                )
                
                # Extract landmarks
                landmarks = results.pose_landmarks.landmark
                
                # Get visibility information
                visibility = calculate_visibility_score(landmarks)
                
                # Add visibility info
                cv2.putText(
                    annotated_frame,
                    f"Upper body visible: {visibility['upper_body_visible']}",
                    (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.6,
                    (0, 255, 0) if visibility['upper_body_visible'] else (0, 0, 255),
                    2
                )
                
                cv2.putText(
                    annotated_frame,
                    f"Lower body visible: {visibility['lower_body_visible']}",
                    (10, 60),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.6,
                    (0, 255, 0) if visibility['lower_body_visible'] else (0, 0, 255),
                    2
                )
                
                # Calculate and display metrics
                y_pos = 90
                metrics = []
                
                # Get shoulders data
                if visibility['upper_body_visible']:
                    left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                                    landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER].y]
                    right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                                     landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER].y]
                    
                    from services.pose_analysis_service import calculate_tilt_angle
                    shoulder_tilt = calculate_tilt_angle(left_shoulder, right_shoulder)
                    metrics.append(("Shoulder tilt", shoulder_tilt))
                    
                    # Get head position
                    head_metrics = calculate_head_position(landmarks, mp_pose)
                    if head_metrics:
                        if head_metrics['head_tilt'] is not None:
                            metrics.append(("Head tilt", head_metrics['head_tilt']))
                        metrics.append(("Forward lean", head_metrics['forward_lean']))
                
                # Get hip and spine data if available
                if visibility['lower_body_visible']:
                    left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP].x,
                               landmarks[mp_pose.PoseLandmark.LEFT_HIP].y]
                    right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP].x,
                                landmarks[mp_pose.PoseLandmark.RIGHT_HIP].y]
                    
                    hip_tilt = calculate_tilt_angle(left_hip, right_hip)
                    metrics.append(("Hip tilt", hip_tilt))
                    
                    # Calculate spine alignment
                    spine_metrics = calculate_spine_alignment(landmarks, mp_pose)
                    if spine_metrics:
                        metrics.append(("Spine angle", spine_metrics['spine_angle']))
                        metrics.append(("Lateral lean", spine_metrics['lateral_lean']))
                
                # Display metrics on frame
                for metric_name, value in metrics:
                    cv2.putText(
                        annotated_frame,
                        f"{metric_name}: {value:.1f}°",
                        (10, y_pos),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (255, 0, 0),
                        2
                    )
                    y_pos += 30
                
            else:
                cv2.putText(
                    annotated_frame,
                    "No pose detected",
                    (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.7,
                    (0, 0, 255),
                    2
                )
            
            # Add frame number
            cv2.putText(
                annotated_frame,
                f"Frame: {frame_count}",
                (10, annotated_frame.shape[0] - 20),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (0, 0, 0),
                2
            )
            
            # Save frame
            cv2.imwrite(f"{frames_folder}/frame_{frame_count:04d}.jpg", annotated_frame)
    
    cap.release()
    print(f"Saved {len(os.listdir(frames_folder))} annotated frames to {frames_folder}")

def main():
    parser = argparse.ArgumentParser(description="Test enhanced pose analysis service")
    parser.add_argument("--video", type=str, required=True, help="Path to video file")
    parser.add_argument("--output", type=str, default="pose_analysis_test", help="Output folder")
    parser.add_argument("--save-frames", action="store_true", help="Save annotated frames")
    
    args = parser.parse_args()
    test_pose_analysis(args.video, args.output, args.save_frames)

if __name__ == "__main__":
    main()
