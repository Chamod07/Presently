import cv2
import numpy as np
import mediapipe as mp
import os
import argparse
import math

def assess_frame_quality(frame, min_brightness=40, min_contrast=30, blur_threshold=100):
    """
    Assess the quality of a frame based on brightness, contrast, and blur.
    
    Args:
        frame: Input frame
        min_brightness: Minimum average brightness (0-255)
        min_contrast: Minimum standard deviation of pixel values
        blur_threshold: Threshold for Laplacian variance (lower = more blurry)
        
    Returns:
        Dict with quality metrics and boolean indicating if frame passes quality check
    """
    # Convert to grayscale for quality assessment
    if len(frame.shape) == 3:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    else:
        gray = frame
    
    # Calculate brightness (mean pixel value)
    brightness = np.mean(gray)
    
    # Calculate contrast (standard deviation of pixel values)
    contrast = np.std(gray)
    
    # Calculate blurriness (variance of Laplacian)
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    blur_score = np.var(laplacian)
    
    # Check if frame passes quality thresholds
    passes_brightness = brightness >= min_brightness
    passes_contrast = contrast >= min_contrast
    passes_blur = blur_score >= blur_threshold
    
    passes_quality = passes_brightness and passes_contrast and passes_blur
    
    return {
        "passes_quality": passes_quality,
        "brightness": brightness,
        "contrast": contrast,
        "blur_score": blur_score,
        "passes_brightness": passes_brightness,
        "passes_contrast": passes_contrast,
        "passes_blur": passes_blur
    }

def detect_motion_blur(frame, prev_frame, motion_threshold=25):
    """
    Detect motion blur by comparing consecutive frames.
    
    Args:
        frame: Current frame
        prev_frame: Previous frame
        motion_threshold: Threshold for average frame difference
        
    Returns:
        True if motion blur detected, False otherwise
    """
    if prev_frame is None:
        return False
    
    # Convert to grayscale
    if len(frame.shape) == 3:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        prev_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
    else:
        gray = frame
        prev_gray = prev_frame
    
    # Calculate absolute difference between frames
    frame_diff = cv2.absdiff(gray, prev_gray)
    mean_diff = np.mean(frame_diff)
    
    # Calculate blur in current frame
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    blur_score = np.var(laplacian)
    
    # If there's significant motion AND the frame is blurry, it's likely motion blur
    return mean_diff > motion_threshold and blur_score < 100

def filter_video_frames(video_path, output_folder, quality_threshold=0.6, sample_rate=1):
    """
    Filter video frames based on quality metrics and save good frames.
    
    Args:
        video_path: Path to input video
        output_folder: Folder to save filtered frames
        quality_threshold: Fraction of quality checks that must pass (0.0-1.0)
        sample_rate: Process every Nth frame (1 = all frames)
        
    Returns:
        Dict with filtering statistics
    """
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video not found: {video_path}")
        
    os.makedirs(output_folder, exist_ok=True)
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    frame_count = 0
    good_frames = 0
    prev_frame = None
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
            
        frame_count += 1
        
        # Skip frames according to sample rate
        if frame_count % sample_rate != 0:
            continue
        
        # Assess frame quality
        quality = assess_frame_quality(frame)
        
        # Check for motion blur
        has_motion_blur = detect_motion_blur(frame, prev_frame)
        
        # Calculate overall quality score
        quality_checks = [
            quality["passes_brightness"],
            quality["passes_contrast"],
            quality["passes_blur"]
        ]
        if prev_frame is not None:
            quality_checks.append(not has_motion_blur)
            
        quality_score = sum(1 for check in quality_checks if check) / len(quality_checks)
        frame_passes = quality_score >= quality_threshold
        
        # Save frame if it passes quality threshold
        if frame_passes:
            good_frames += 1
            frame_filename = f"{output_folder}/frame_{frame_count:04d}.jpg"
            cv2.imwrite(frame_filename, frame)
            
            # Add quality info to frame
            annotated_frame = frame.copy()
            cv2.putText(
                annotated_frame,
                f"Quality: {quality_score:.2f}",
                (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                1,
                (0, 255, 0),
                2
            )
            
            # Add detailed metrics
            metrics_frame = annotated_frame.copy()
            y_pos = 70
            for metric, value in quality.items():
                if metric != "passes_quality":
                    cv2.putText(
                        metrics_frame,
                        f"{metric}: {value}",
                        (10, y_pos),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (0, 255, 0) if isinstance(value, bool) and value else (0, 0, 255) if isinstance(value, bool) else (255, 0, 0),
                        2
                    )
                    y_pos += 30
            
            # Save annotated frame
            cv2.imwrite(f"{output_folder}/annotated_frame_{frame_count:04d}.jpg", metrics_frame)
        
        # Store current frame for next iteration
        prev_frame = frame
    
    # Release video
    cap.release()
    
    # Calculate statistics
    good_frame_rate = good_frames / (frame_count / sample_rate) if frame_count > 0 else 0
    
    stats = {
        "total_frames_processed": frame_count // sample_rate,
        "good_frames": good_frames,
        "good_frame_rate": good_frame_rate,
        "quality_threshold": quality_threshold
    }
    
    # Save statistics
    with open(f"{output_folder}/filter_stats.txt", "w") as f:
        f.write("Frame Filtering Statistics\n")
        f.write("=======================\n\n")
        f.write(f"Video: {video_path}\n")
        f.write(f"Total frames processed: {stats['total_frames_processed']}\n")
        f.write(f"Good frames: {stats['good_frames']}\n")
        f.write(f"Good frame rate: {stats['good_frame_rate']:.2f}\n")
        f.write(f"Quality threshold: {stats['quality_threshold']}\n")
    
    print(f"Frame filtering complete. {good_frames} good frames saved to {output_folder}/")
    return stats

def main():
    parser = argparse.ArgumentParser(description="Filter video frames based on quality")
    parser.add_argument("--video", required=True, help="Path to input video")
    parser.add_argument("--output", default="filtered_frames", help="Output folder for filtered frames")
    parser.add_argument("--threshold", type=float, default=0.6, help="Quality threshold (0.0-1.0)")
    parser.add_argument("--sample-rate", type=int, default=1, help="Process every Nth frame")
    
    args = parser.parse_args()
    filter_video_frames(args.video, args.output, args.threshold, args.sample_rate)

if __name__ == "__main__":
    main()
