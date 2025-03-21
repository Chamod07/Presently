import os
import cv2
import numpy as np
import matplotlib.pyplot as plt
import argparse
import json
import time
from datetime import datetime
from tabulate import tabulate
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor

from utils.pose_validation import validate_pose_detection
from utils.pose_model_validator import validate_model_accuracy
from utils.frame_quality_filter import filter_video_frames
from services.pose_analysis_service import analyze_posture

class PoseBenchmarker:
    """
    Comprehensive benchmarking utility for pose analysis that integrates multiple validation tools.
    """
    
    def __init__(self, output_dir="benchmark_results"):
        """Initialize benchmarker with output directory."""
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.results = {}
        
    def run_comprehensive_benchmark(self, video_path, ground_truth_path=None):
        """
        Run comprehensive benchmarking on a video using all available tools.
        
        Args:
            video_path: Path to test video
            ground_truth_path: Path to ground truth data (optional)
        """
        print(f"Running comprehensive benchmark on {video_path}")
        test_id = f"test_{os.path.basename(video_path).split('.')[0]}_{self.timestamp}"
        test_dir = os.path.join(self.output_dir, test_id)
        os.makedirs(test_dir, exist_ok=True)
        
        benchmark_results = {}
        
        # Step 1: Validate frame quality
        print("\n1. Validating frame quality...")
        quality_dir = os.path.join(test_dir, "frame_quality")
        quality_results = self._benchmark_frame_quality(video_path, quality_dir)
        benchmark_results["frame_quality"] = quality_results
        
        # Step 2: Find optimal model settings
        print("\n2. Finding optimal pose model settings...")
        model_dir = os.path.join(test_dir, "model_validation")
        model_results = self._benchmark_model_settings(video_path, model_dir, ground_truth_path)
        benchmark_results["model_settings"] = model_results
        
        # Step 3: Validate pose detection
        print("\n3. Validating pose detection...")
        pose_dir = os.path.join(test_dir, "pose_validation")
        pose_results = self._benchmark_pose_detection(video_path, pose_dir)
        benchmark_results["pose_detection"] = pose_results
        
        # Step 4: Run full pose analysis
        print("\n4. Running full pose analysis...")
        analysis_dir = os.path.join(test_dir, "pose_analysis")
        os.makedirs(analysis_dir, exist_ok=True)
        analysis_results = analyze_posture(video_path)
        
        # Step 5: Run facial expression analysis
        print("\n5. Running facial expression & eye contact analysis...")
        try:
            from services.facial_analysis_service import analyze_facial_engagement
            facial_results = analyze_facial_engagement(video_path)
            analysis_results["facial_analysis"] = facial_results
            
            benchmark_results["facial_analysis"] = {
                "detection_rate": facial_results.get("detection_rate", 0),
                "avg_engagement": facial_results.get("engagement_metrics", {}).get("average", 0),
                "eye_contact_ratio": facial_results.get("eye_contact_ratio", 0),
                "dominant_expression": facial_results.get("dominant_expression", "unknown")
            }
        except Exception as e:
            print(f"Error during facial analysis: {str(e)}")
            benchmark_results["facial_analysis"] = {"error": str(e)}
        
        # Save analysis results
        with open(os.path.join(analysis_dir, "analysis_results.json"), "w") as f:
            json_data = {k: v for k, v in analysis_results.items() if k != 'aggregate_metrics'}
            # Convert metrics to serializable format
            if 'aggregate_metrics' in analysis_results:
                json_data['aggregate_metrics'] = {}
                for metric, values in analysis_results['aggregate_metrics'].items():
                    json_data['aggregate_metrics'][metric] = {
                        k: float(v) for k, v in values.items()
                    }
            json.dump(json_data, f, indent=2)
        benchmark_results["pose_analysis"] = {
            "detection_rate": analysis_results.get("detection_rate", 0),
            "analysis_mode": analysis_results.get("analysis_mode", "unknown"),
            "poor_posture_percentage": analysis_results.get("poor_posture_percentage", 0),
            "main_issues_count": len(analysis_results.get("main_issues", []))
        }
        
        # Generate summary report
        self._generate_summary_report(benchmark_results, test_dir, video_path)
        
        # Store results
        self.results[test_id] = benchmark_results
        
        print(f"\nBenchmark completed. Results saved to {test_dir}")
        return benchmark_results, test_dir
        
    def _benchmark_frame_quality(self, video_path, output_dir):
        """Benchmark frame quality."""
        try:
            # Use the frame quality filter with a higher sample rate for efficiency
            stats = filter_video_frames(video_path, output_dir, quality_threshold=0.5, sample_rate=10)
            return {
                "total_frames": stats["total_frames_processed"] * 10,  # Account for sampling rate
                "good_frames": stats["good_frames"],
                "good_frame_rate": stats["good_frame_rate"]
            }
        except Exception as e:
            print(f"Error during frame quality assessment: {str(e)}")
            return {"error": str(e)}
    
    def _benchmark_model_settings(self, video_path, output_dir, ground_truth_path=None):
        """Benchmark different model settings."""
        try:
            best_settings = validate_model_accuracy(video_path, ground_truth_path, output_dir)
            return best_settings
        except Exception as e:
            print(f"Error during model validation: {str(e)}")
            return {"error": str(e)}
    
    def _benchmark_pose_detection(self, video_path, output_dir):
        """Benchmark pose detection."""
        try:
            # Run pose validation (saving only a subset of frames)
            results = validate_pose_detection(video_path, output_dir, save_frames=True)
            
            # Extract key metrics
            return {
                "detection_rate": results["detection_rate"],
                "visibility_patterns": results["visibility_patterns"],
                "detection_stats": {k: v for k, v in results["detection_stats"].items()}
            }
        except Exception as e:
            print(f"Error during pose detection validation: {str(e)}")
            return {"error": str(e)}
    
    def _generate_summary_report(self, results, output_dir, video_path):
        """Generate a summary report of all benchmarks."""
        summary_file = os.path.join(output_dir, "benchmark_summary.txt")
        
        with open(summary_file, "w") as f:
            f.write("Comprehensive Pose Analysis Benchmark Summary\n")
            f.write("===========================================\n\n")
            f.write(f"Video: {video_path}\n")
            f.write(f"Benchmark Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            # Frame quality summary
            f.write("Frame Quality Assessment\n")
            f.write("-----------------------\n")
            if "error" in results.get("frame_quality", {}):
                f.write(f"Error: {results['frame_quality']['error']}\n")
            else:
                quality = results.get("frame_quality", {})
                f.write(f"Total frames: {quality.get('total_frames', 'N/A')}\n")
                f.write(f"Good quality frames: {quality.get('good_frames', 'N/A')}\n")
                f.write(f"Good frame rate: {quality.get('good_frame_rate', 'N/A'):.1f}%\n")
            f.write("\n")
            
            # Model settings summary
            f.write("Optimal Model Settings\n")
            f.write("--------------------\n")
            if "error" in results.get("model_settings", {}):
                f.write(f"Error: {results['model_settings']['error']}\n")
            else:
                settings = results.get("model_settings", {})
                f.write(f"Model complexity: {settings.get('model_complexity', 'N/A')}\n")
                f.write(f"Min detection confidence: {settings.get('min_detection_confidence', 'N/A')}\n")
                f.write(f"Min tracking confidence: {settings.get('min_tracking_confidence', 'N/A')}\n")
            f.write("\n")
            
            # Pose detection summary
            f.write("Pose Detection Results\n")
            f.write("--------------------\n")
            if "error" in results.get("pose_detection", {}):
                f.write(f"Error: {results['pose_detection']['error']}\n")
            else:
                detection = results.get("pose_detection", {})
                f.write(f"Detection rate: {detection.get('detection_rate', 'N/A'):.1f}%\n")
                
                if "detection_stats" in detection:
                    stats = detection["detection_stats"]
                    f.write(f"Frames with pose detected: {stats.get('detected', 'N/A')}\n")
                    f.write(f"Frames with upper body only: {stats.get('upper_body_only', 'N/A')}\n")
                    f.write(f"Frames with full body: {stats.get('full_body', 'N/A')}\n")
                
                if "visibility_patterns" in detection:
                    viz = detection["visibility_patterns"]
                    f.write("\nVisibility statistics:\n")
                    for part, count in viz.items():
                        f.write(f"- {part.replace('_', ' ').title()}: {count} frames\n")
            f.write("\n")
            
            # Pose analysis summary
            f.write("Full Pose Analysis Results\n")
            f.write("------------------------\n")
            if "error" in results.get("pose_analysis", {}):
                f.write(f"Error: {results['pose_analysis']['error']}\n")
            else:
                analysis = results.get("pose_analysis", {})
                f.write(f"Detection rate: {analysis.get('detection_rate', 'N/A'):.1f}%\n")
                f.write(f"Analysis mode: {analysis.get('analysis_mode', 'N/A')}\n")
                f.write(f"Poor posture percentage: {analysis.get('poor_posture_percentage', 'N/A'):.1f}%\n")
                f.write(f"Number of posture issues detected: {analysis.get('main_issues_count', 'N/A')}\n")
            f.write("\n")
            
            # Facial analysis summary
            f.write("Facial Expression & Eye Contact Analysis\n")
            f.write("---------------------------------------\n")
            if "error" in results.get("facial_analysis", {}):
                f.write(f"Error: {results['facial_analysis']['error']}\n")
            else:
                facial = results.get("facial_analysis", {})
                f.write(f"Detection rate: {facial.get('detection_rate', 'N/A'):.1f}%\n")
                f.write(f"Average engagement: {facial.get('avg_engagement', 'N/A'):.1f}%\n")
                f.write(f"Eye contact ratio: {facial.get('eye_contact_ratio', 'N/A'):.1f}%\n")
                f.write(f"Dominant expression: {facial.get('dominant_expression', 'N/A')}\n")
            f.write("\n")
            
            # Overall assessment
            f.write("Overall Assessment\n")
            f.write("-----------------\n")
            
            # Calculate overall quality score (0-100)
            quality_score = 0
            components = 0
            
            if "frame_quality" in results and "good_frame_rate" in results["frame_quality"]:
                quality_score += results["frame_quality"]["good_frame_rate"]
                components += 1
                
            if "pose_detection" in results and "detection_rate" in results["pose_detection"]:
                quality_score += results["pose_detection"]["detection_rate"]
                components += 1
                
            if "pose_analysis" in results and "detection_rate" in results["pose_analysis"]:
                quality_score += results["pose_analysis"]["detection_rate"]
                components += 1
            
            if components > 0:
                quality_score = quality_score / components
                f.write(f"Overall quality score: {quality_score:.1f}/100\n")
                
                if quality_score >= 90:
                    f.write("Assessment: Excellent - High-quality video with reliable pose detection\n")
                elif quality_score >= 75:
                    f.write("Assessment: Good - Reliable pose detection with acceptable quality\n")
                elif quality_score >= 60:
                    f.write("Assessment: Fair - Usable for analysis but some frames may be unreliable\n")
                elif quality_score >= 40:
                    f.write("Assessment: Poor - Many frames with detection issues, analysis may be limited\n")
                else:
                    f.write("Assessment: Very Poor - Video not suitable for accurate pose analysis\n")
            else:
                f.write("Assessment: Unable to calculate quality score\n")
        
        print(f"Summary report saved to {summary_file}")

def main():
    """Main function to run the benchmarker."""
    parser = argparse.ArgumentParser(description="Comprehensive pose analysis benchmarking tool")
    parser.add_argument("--video", required=True, help="Path to input video")
    parser.add_argument("--ground-truth", help="Path to ground truth data (optional)")
    parser.add_argument("--output", default="benchmark_results", help="Output directory")
    
    args = parser.parse_args()
    
    benchmarker = PoseBenchmarker(args.output)
    benchmarker.run_comprehensive_benchmark(args.video, args.ground_truth)

if __name__ == "__main__":
    main()
