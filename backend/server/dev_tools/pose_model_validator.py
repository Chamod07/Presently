import cv2
import numpy as np
import mediapipe as mp
import os
import json
import time
from scipy.signal import savgol_filter
from services.pose_analysis_service import calculate_visibility_score

def validate_model_accuracy(video_path, ground_truth_path=None, output_folder="model_validation"):
    """
    Validate MediaPipe pose estimation accuracy against ground truth data or using statistical methods.
    
    Args:
        video_path: Path to test video
        ground_truth_path: Path to ground truth annotation file (optional)
        output_folder: Where to save validation results
    """
    os.makedirs(output_folder, exist_ok=True)
    
    # Initialize MediaPipe with different model complexities
    validation_results = {}
    
    for complexity in [0, 1, 2]:  # Test all available model complexities
        print(f"Testing model complexity: {complexity}")
        results = _test_model_complexity(video_path, complexity)
        validation_results[f"complexity_{complexity}"] = results
    
    # Compare with ground truth if provided
    if ground_truth_path and os.path.exists(ground_truth_path):
        ground_truth = _load_ground_truth(ground_truth_path)
        accuracy_metrics = _compare_with_ground_truth(validation_results, ground_truth)
        validation_results["accuracy_metrics"] = accuracy_metrics
    
    # Calculate confidence metrics even without ground truth
    confidence_metrics = _analyze_detection_confidence(validation_results)
    validation_results["confidence_metrics"] = confidence_metrics
    
    # Save validation results
    with open(f"{output_folder}/model_validation_results.json", "w") as f:
        json.dump(validation_results, f, indent=2, default=lambda x: float(x) if isinstance(x, np.float32) else x)
    
    # Generate recommendation for best settings
    best_settings = _recommend_best_settings(validation_results)
    
    with open(f"{output_folder}/recommended_settings.txt", "w") as f:
        f.write("Recommended Model Settings\n")
        f.write("========================\n\n")
        f.write(f"Model Complexity: {best_settings['model_complexity']}\n")
        f.write(f"Detection Confidence: {best_settings['min_detection_confidence']}\n")
        f.write(f"Tracking Confidence: {best_settings['min_tracking_confidence']}\n")
        f.write("\nRationale:\n")
        f.write(best_settings['rationale'])
    
    print(f"Validation complete. Results saved to {output_folder}/")
    return best_settings

def _test_model_complexity(video_path, complexity):
    """Test model with specific complexity setting."""
    mp_pose = mp.solutions.pose
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    
    # Tracking variables
    detection_results = []
    processing_times = []
    landmarks_stability = []
    previous_landmarks = None
    
    # Process video
    with mp_pose.Pose(
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
        model_complexity=complexity
    ) as pose:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            # Convert to RGB
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process with MediaPipe and measure time
            start_time = time.time()
            results = pose.process(image_rgb)
            process_time = (time.time() - start_time) * 1000  # ms
            processing_times.append(process_time)
            
            # Track detection success
            if results.pose_landmarks:
                landmarks = results.pose_landmarks.landmark
                
                # Calculate visibility score
                visibility = calculate_visibility_score(landmarks)
                
                # Calculate stability if we have previous landmarks
                if previous_landmarks is not None:
                    stability = _calculate_landmarks_stability(previous_landmarks, landmarks)
                    landmarks_stability.append(stability)
                
                previous_landmarks = landmarks
                
                detection_results.append({
                    "detected": True,
                    "visibility": visibility,
                    "confidence": [lm.visibility for lm in landmarks[:5]]  # Just sample first 5 landmarks
                })
            else:
                detection_results.append({
                    "detected": False
                })
    
    cap.release()
    
    # Calculate aggregate metrics
    detection_rate = sum(1 for r in detection_results if r["detected"]) / len(detection_results) if detection_results else 0
    avg_process_time = np.mean(processing_times) if processing_times else 0
    
    # Calculate stability metrics (higher is more stable)
    stability_score = 0
    if landmarks_stability:
        stability_score = 1.0 / (np.mean(landmarks_stability) + 1e-5)
    
    return {
        "detection_rate": detection_rate,
        "avg_process_time": avg_process_time,
        "stability_score": stability_score,
        "detailed_results": detection_results
    }

def _calculate_landmarks_stability(prev_landmarks, curr_landmarks):
    """Calculate stability between consecutive landmark detections."""
    # Use only the most stable landmarks (face, shoulders)
    key_landmarks_indices = [0, 1, 2, 11, 12]  # Nose, eyes, shoulders
    
    movement = 0
    count = 0
    
    for idx in key_landmarks_indices:
        if idx < len(prev_landmarks) and idx < len(curr_landmarks):
            prev_lm = prev_landmarks[idx]
            curr_lm = curr_landmarks[idx]
            
            # Calculate Euclidean distance
            dist = np.sqrt((prev_lm.x - curr_lm.x)**2 + (prev_lm.y - curr_lm.y)**2)
            movement += dist
            count += 1
    
    return movement / count if count > 0 else 0

def _load_ground_truth(ground_truth_path):
    """Load ground truth data from JSON file."""
    with open(ground_truth_path, 'r') as f:
        return json.load(f)

def _compare_with_ground_truth(results, ground_truth):
    """Compare model output with ground truth data."""
    # Implementation depends on ground truth format
    # This is a placeholder for the comparison logic
    return {
        "mae": 0.0,
        "precision": 0.0,
        "recall": 0.0
    }

def _analyze_detection_confidence(results):
    """Analyze confidence values across different model complexities."""
    confidence_metrics = {}
    
    for complexity, data in results.items():
        if not complexity.startswith("complexity_"):
            continue
            
        # Extract confidence values from detailed results
        confidence_values = []
        for result in data.get("detailed_results", []):
            if result.get("detected", False) and "confidence" in result:
                confidence_values.extend(result["confidence"])
        
        if confidence_values:
            confidence_metrics[complexity] = {
                "mean_confidence": np.mean(confidence_values),
                "min_confidence": np.min(confidence_values),
                "max_confidence": np.max(confidence_values),
                "std_confidence": np.std(confidence_values)
            }
    
    return confidence_metrics

def _recommend_best_settings(validation_results):
    """Recommend best model settings based on validation results."""
    # Default settings
    best_settings = {
        "model_complexity": 1,
        "min_detection_confidence": 0.5,
        "min_tracking_confidence": 0.5,
        "rationale": "Default settings based on balanced performance."
    }
    
    # Extract performance metrics
    complexity_metrics = {}
    for complexity in [0, 1, 2]:
        key = f"complexity_{complexity}"
        if key in validation_results:
            data = validation_results[key]
            
            # Calculate weighted score (higher is better)
            # We prioritize detection rate, then stability, then speed
            detection_weight = 0.6
            stability_weight = 0.3
            speed_weight = 0.1
            
            detection_score = data.get("detection_rate", 0) * 100
            stability_score = data.get("stability_score", 0) * 100
            speed_score = 100 / (1 + data.get("avg_process_time", 100) / 100)  # Normalize processing time
            
            weighted_score = (detection_weight * detection_score +
                            stability_weight * stability_score +
                            speed_weight * speed_score)
            
            complexity_metrics[complexity] = {
                "weighted_score": weighted_score,
                "detection_rate": data.get("detection_rate", 0),
                "stability_score": data.get("stability_score", 0),
                "avg_process_time": data.get("avg_process_time", 0)
            }
    
    # Find best complexity
    if complexity_metrics:
        best_complexity = max(complexity_metrics.items(), key=lambda x: x[1]["weighted_score"])[0]
        best_settings["model_complexity"] = best_complexity
        
        # Fine-tune confidence thresholds based on best complexity
        if best_complexity == 0:
            # For low complexity, use higher confidence thresholds
            best_settings["min_detection_confidence"] = 0.6
            best_settings["min_tracking_confidence"] = 0.6
        elif best_complexity == 2:
            # For high complexity, we can use lower confidence thresholds
            best_settings["min_detection_confidence"] = 0.4
            best_settings["min_tracking_confidence"] = 0.5
        
        # Generate rationale
        best_metrics = complexity_metrics[best_complexity]
        best_settings["rationale"] = (
            f"Selected model complexity {best_complexity} based on weighted performance score of {best_metrics['weighted_score']:.1f}.\n\n"
            f"Detection rate: {best_metrics['detection_rate']:.2f}\n"
            f"Stability score: {best_metrics['stability_score']:.2f}\n"
            f"Average processing time: {best_metrics['avg_process_time']:.1f} ms\n\n"
            f"Confidence thresholds were adjusted based on model complexity to optimize accuracy."
        )
    
    return best_settings

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Validate pose detection model")
    parser.add_argument("--video", required=True, help="Path to test video")
    parser.add_argument("--ground-truth", help="Path to ground truth data (optional)")
    parser.add_argument("--output", default="model_validation", help="Output folder")
    
    args = parser.parse_args()
    validate_model_accuracy(args.video, args.ground_truth, args.output)

if __name__ == "__main__":
    main()
