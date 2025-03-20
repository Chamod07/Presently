import os
import warnings
import cv2
import numpy as np
import math
import logging
from datetime import datetime
from collections import deque
from services.logging_utils import suppress_stdout_stderr, init_mediapipe

# Basic warning suppression
warnings.filterwarnings("ignore")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['MEDIAPIPE_DISABLE_GPU'] = '1'

# Initialize MediaPipe silently
mp = init_mediapipe()
mp_pose = mp.solutions.pose

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def analyze_posture(video_path):
    """
    Simplified posture analysis focusing on core metrics only.
    
    Args:
        video_path: Path to the video file
    """
    # Check if the video file exists
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video file not found at path: {video_path}")

    logger.info(f"Starting simplified posture analysis for: {video_path}")
    
    # Open video
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError("Could not open video file")
    
    frame_rate = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Analysis tracking variables
    processed_frames = 0
    detected_frames = 0
    
    # Core posture metrics - expanded to include more metrics
    posture_data = {
        'head_tilt_frames': 0,
        'forward_lean_frames': 0,
        'shoulder_imbalance_frames': 0,
        'slouching_frames': 0,
        'eye_contact_frames': 0,  # New: track eye contact (looking at camera)
        'rigid_posture_frames': 0,  # New: track overly stiff posture
        'excessive_movement_frames': 0,  # New: track excessive movement
        'hand_position_frames': 0,  # New: track inappropriate hand position
    }
    
    # Track frame sequences for movement analysis
    position_history = []
    
    # Skip interval (process 1 frame per second for efficiency)
    skip_interval = max(1, int(frame_rate))
    
    # Process video with simplified settings
    with mp_pose.Pose(
        min_detection_confidence=0.5,  # Lower threshold to detect more poses
        min_tracking_confidence=0.5,
        model_complexity=1,  # Medium complexity for balance
        smooth_landmarks=True
    ) as pose:
        frame_count = 0
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_count += 1
            
            # Skip frames for efficiency
            if frame_count % skip_interval != 0:
                continue
                
            processed_frames += 1
            
            # Resize large frames for better performance
            h, w = frame.shape[:2]
            if w > 640:
                resize_factor = 640 / w
                frame = cv2.resize(frame, (640, int(h * resize_factor)))
            
            # Convert to RGB and process
            image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(image)
            
            if results.pose_landmarks:
                detected_frames += 1
                landmarks = results.pose_landmarks.landmark
                
                # Store position for movement analysis
                position = extract_position(landmarks)
                if position:
                    position_history.append(position)
                
                # Simple posture checks
                # 1. Head tilt check
                if is_head_tilted(landmarks):
                    posture_data['head_tilt_frames'] += 1
                
                # 2. Forward lean check
                if is_leaning_forward(landmarks):
                    posture_data['forward_lean_frames'] += 1
                
                # 3. Shoulder imbalance check
                if has_shoulder_imbalance(landmarks):
                    posture_data['shoulder_imbalance_frames'] += 1
                
                # 4. Slouching check
                if is_slouching(landmarks):
                    posture_data['slouching_frames'] += 1
                    
                # 5. Eye contact check (based on face orientation)
                if not has_good_eye_contact(landmarks):
                    posture_data['eye_contact_frames'] += 1
                    
                # 6. Rigid posture check
                if has_rigid_posture(landmarks):
                    posture_data['rigid_posture_frames'] += 1
                    
                # 7. Hand position check
                if has_poor_hand_position(landmarks):
                    posture_data['hand_position_frames'] += 1
    
    cap.release()
    
    # Process movement data
    if len(position_history) > 10:
        excessive_movement = analyze_movement(position_history)
        posture_data['excessive_movement_frames'] = int(excessive_movement * detected_frames)
    
    # Calculate detection quality
    detection_rate = (detected_frames / processed_frames) * 100 if processed_frames > 0 else 0
    
    # Only proceed with analysis if we have enough detected frames
    if detected_frames < 5 or detection_rate < 20:
        # Create default issue for poor detection
        default_issues = [{
            "topic": "Poor Video Quality",
            "examples": ["Your video had poor detection quality. Make sure you are clearly visible."],
            "suggestions": ["Ensure good lighting and that your upper body is clearly visible in the frame."],
            "severity": "high",
            "impact": "Critical - Without clear video, we cannot analyze your body language effectively."
        }]
        return {
            'score': 5,  # Default middle score
            'detected_frames': detected_frames,
            'detection_rate': detection_rate,
            'error': "Insufficient pose detection. Please ensure upper body is clearly visible.",
            'issues': default_issues
        }
    
    # Calculate issue percentages
    issues = []
    main_issues = []
    
    if detected_frames > 0:
        for issue_name, frames in posture_data.items():
            percentage = (frames / detected_frames) * 100
            # Lower threshold to 15% to catch more issues
            if percentage > 15:
                issues.append({
                    'issue': issue_name.replace('_frames', '').replace('_', ' ').title(),
                    'percentage': percentage
                })
    
    # Sort issues by percentage (highest first)
    issues.sort(key=lambda x: x['percentage'], reverse=True)
    
    # Convert to user-friendly format and add suggestions
    for issue in issues:
        friendly_name = issue['issue']
        percentage = issue['percentage']
        suggestion, severity, impact = get_detailed_feedback(friendly_name, percentage)
        
        # Combine severity and impact with the suggestion for a more complete feedback
        enhanced_suggestion = f"{suggestion} [{severity.upper()}] {impact}"
        
        main_issues.append({
            "topic": friendly_name,
            "examples": [f"Observed in {percentage:.1f}% of your presentation"],
            "suggestions": [enhanced_suggestion]
        })
    
    # If no issues detected, provide generic feedback
    if not main_issues:
        main_issues = [{
            "topic": "Good Posture Maintained",
            "examples": ["You maintained good posture throughout your presentation."],
            "suggestions": ["Continue maintaining good posture in future presentations. [POSITIVE] Your good posture contributes to a professional presentation style."]
        }]
    
    # Calculate more nuanced score based on detected issues
    # Base score is 9, subtract points based on severity and percentage
    score = calculate_score(issues)
    
    # Log the detected issues to help with debugging
    print(f"Detected {len(main_issues)} posture issues:")
    for issue in main_issues:
        print(f"  - {issue['topic']}")
    
    return {
        'score': score,
        'detected_frames': detected_frames,
        'detection_rate': detection_rate,
        'issues': main_issues
    }

def extract_position(landmarks):
    """Extract key position data for movement analysis"""
    try:
        # Use nose as the central tracking point
        nose = landmarks[mp_pose.PoseLandmark.NOSE]
        if nose.visibility < 0.5:
            return None
        return {
            'x': nose.x,
            'y': nose.y,
            'visibility': nose.visibility
        }
    except:
        return None

def analyze_movement(position_history):
    """Analyze movement patterns and return excessive movement ratio (0-1)"""
    try:
        # Calculate frame-to-frame movement
        movements = []
        for i in range(1, len(position_history)):
            prev = position_history[i-1]
            curr = position_history[i]
            
            # Calculate Euclidean distance
            distance = math.sqrt(
                (curr['x'] - prev['x'])**2 + 
                (curr['y'] - prev['y'])**2
            )
            movements.append(distance)
        
        # Calculate statistics
        avg_movement = np.mean(movements)
        
        # Threshold for excessive movement (calibrated for webcam)
        if avg_movement > 0.03:  # Significant movements
            return 0.8  # 80% of frames have excessive movement
        elif avg_movement > 0.015:  # Moderate movements
            return 0.5  # 50% of frames have excessive movement
        elif avg_movement > 0.01:  # Slight movements
            return 0.2  # 20% of frames have excessive movement
        else:
            return 0  # No excessive movement
    except:
        return 0

def is_head_tilted(landmarks):
    """Simple check for head tilt."""
    try:
        left_ear = landmarks[mp_pose.PoseLandmark.LEFT_EAR]
        right_ear = landmarks[mp_pose.PoseLandmark.RIGHT_EAR]
        
        if left_ear.visibility < 0.5 or right_ear.visibility < 0.5:
            return False
            
        y_diff = abs(left_ear.y - right_ear.y)
        # Lower threshold to catch more issues
        return y_diff > 0.02
    except:
        return False

def is_leaning_forward(landmarks):
    """Simple check for forward leaning."""
    try:
        nose = landmarks[mp_pose.PoseLandmark.NOSE]
        left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
        right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
        
        if nose.visibility < 0.5 or left_shoulder.visibility < 0.5 or right_shoulder.visibility < 0.5:
            return False
            
        shoulder_x = (left_shoulder.x + right_shoulder.x) / 2
        horizontal_diff = abs(nose.x - shoulder_x)
        # Lower threshold to catch more issues
        return horizontal_diff > 0.08
    except:
        return False

def has_shoulder_imbalance(landmarks):
    """Simple check for uneven shoulders."""
    try:
        left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
        right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
        
        if left_shoulder.visibility < 0.5 or right_shoulder.visibility < 0.5:
            return False
            
        y_diff = abs(left_shoulder.y - right_shoulder.y)
        # Lower threshold to catch more issues
        return y_diff > 0.025
    except:
        return False

def is_slouching(landmarks):
    """Simple check for slouching posture."""
    try:
        left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
        right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
        left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
        right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
        
        # Require good visibility of all landmarks
        if (left_shoulder.visibility < 0.5 or right_shoulder.visibility < 0.5 or
            left_hip.visibility < 0.5 or right_hip.visibility < 0.5):
            return False
            
        # Calculate back angle from vertical
        shoulder_midpoint = [(left_shoulder.x + right_shoulder.x) / 2, (left_shoulder.y + right_shoulder.y) / 2]
        hip_midpoint = [(left_hip.x + right_hip.x) / 2, (left_hip.y + right_hip.y) / 2]
        
        # A straight back should have the shoulders directly above hips
        # If shoulders are significantly forward of hips, that's slouching
        x_diff = shoulder_midpoint[0] - hip_midpoint[0]
        # Lower threshold to catch more issues
        return x_diff > 0.04
    except:
        return False

def has_good_eye_contact(landmarks):
    """Check if the person is looking at the camera (approximation)"""
    try:
        # We use nose and eyes to estimate gaze direction
        nose = landmarks[mp_pose.PoseLandmark.NOSE]
        left_eye = landmarks[mp_pose.PoseLandmark.LEFT_EYE]
        right_eye = landmarks[mp_pose.PoseLandmark.RIGHT_EYE]
        
        if (nose.visibility < 0.7 or left_eye.visibility < 0.7 or 
            right_eye.visibility < 0.7):
            return True  # Default to true if we can't detect well
        
        # Calculate eye midpoint
        eye_midpoint = [(left_eye.x + right_eye.x) / 2, (left_eye.y + right_eye.y) / 2]
        
        # If nose is significantly to the side of eye midpoint, probably not looking at camera
        x_diff = abs(nose.x - eye_midpoint[0])
        return x_diff < 0.02  # Small threshold for "looking at camera"
    except:
        return True  # Default to true in case of error

def has_rigid_posture(landmarks):
    """Check for overly stiff/rigid posture"""
    try:
        # Calculate overall body alignment - perfectly straight might indicate rigidity
        left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
        right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
        left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
        right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
        
        if (left_shoulder.visibility < 0.5 or right_shoulder.visibility < 0.5 or
            left_hip.visibility < 0.5 or right_hip.visibility < 0.5):
            return False
        
        # Calculate how perfectly aligned the body is
        shoulder_midpoint = [(left_shoulder.x + right_shoulder.x) / 2, (left_shoulder.y + right_shoulder.y) / 2]
        hip_midpoint = [(left_hip.x + right_hip.x) / 2, (left_hip.y + right_hip.y) / 2]
        
        # Check vertical alignment - extremely straight posture might be rigid
        x_diff = abs(shoulder_midpoint[0] - hip_midpoint[0])
        return x_diff < 0.01  # Very small threshold indicates rigid posture
    except:
        return False

def has_poor_hand_position(landmarks):
    """Check for inappropriate hand positions"""
    try:
        # Get wrist and hip landmarks
        left_wrist = landmarks[mp_pose.PoseLandmark.LEFT_WRIST]
        right_wrist = landmarks[mp_pose.PoseLandmark.RIGHT_WRIST]
        left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
        right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
        
        if (left_wrist.visibility < 0.5 or right_wrist.visibility < 0.5):
            return False
            
        # Check if hands are behind back or in pockets (close to hips)
        left_hand_near_hip = False
        right_hand_near_hip = False
        
        if left_hip.visibility > 0.5:
            left_distance = math.sqrt(
                (left_wrist.x - left_hip.x)**2 + 
                (left_wrist.y - left_hip.y)**2
            )
            left_hand_near_hip = left_distance < 0.15
            
        if right_hip.visibility > 0.5:
            right_distance = math.sqrt(
                (right_wrist.x - right_hip.x)**2 + 
                (right_wrist.y - right_hip.y)**2
            )
            right_hand_near_hip = right_distance < 0.15
        
        return left_hand_near_hip or right_hand_near_hip
    except:
        return False

def get_detailed_feedback(issue_name, percentage):
    """Return detailed feedback for each issue type, including severity and impact."""
    feedback = {
        "Head Tilt": {
            "mild": {
                "suggestion": "Try to keep your head level during presentations. Practice in front of a mirror to develop awareness of your head position.",
                "impact": "Slight head tilt can be distracting to some audience members."
            },
            "moderate": {
                "suggestion": "Your head tilt is noticeable. Practice keeping your head level by doing alignment exercises and filming yourself to check your posture.",
                "impact": "A consistently tilted head can make you appear less confident and may distract from your message."
            },
            "severe": {
                "suggestion": "Your significant head tilt needs correction. Consider posture exercises focusing on neck alignment, and practice presenting while maintaining a level head position.",
                "impact": "A pronounced head tilt can undermine credibility and distract from your content."
            }
        },
        "Forward Lean": {
            "mild": {
                "suggestion": "Be mindful of how far forward you lean. A slight backward adjustment would improve your posture.",
                "impact": "Occasional forward leaning has minimal impact on your presentation."
            },
            "moderate": {
                "suggestion": "Practice standing straighter with your head aligned with your shoulders. Film yourself presenting to increase awareness of this habit.",
                "impact": "Consistent forward leaning can make you appear anxious or too aggressive."
            },
            "severe": {
                "suggestion": "Work on core strength exercises and practice proper alignment. Stand with your back against a wall when rehearsing to develop muscle memory for proper posture.",
                "impact": "Excessive forward leaning can significantly reduce your perceived confidence and authority."
            }
        },
        "Shoulder Imbalance": {
            "mild": {
                "suggestion": "Be mindful of keeping your shoulders level. Simple shoulder rolls before presenting can help with alignment.",
                "impact": "Slight shoulder imbalance is barely noticeable to most audience members."
            },
            "moderate": {
                "suggestion": "Practice exercises that strengthen your upper back and shoulders. Check your posture in a mirror while rehearsing presentations.",
                "impact": "Uneven shoulders can make you appear tense or uncomfortable."
            },
            "severe": {
                "suggestion": "Consider posture-correcting exercises focusing on shoulder alignment. Film yourself presenting from different angles to increase awareness.",
                "impact": "Very uneven shoulders can distract the audience and may signal nervousness or discomfort."
            }
        },
        "Slouching": {
            "mild": {
                "suggestion": "Try to stand a bit taller when presenting. Simple posture checks before presenting can help.",
                "impact": "Occasional slouching slightly diminishes your commanding presence."
            },
            "moderate": {
                "suggestion": "Practice standing tall with your shoulders back and spine straight. Core-strengthening exercises can help maintain better posture.",
                "impact": "Regular slouching makes you appear less confident and less authoritative."
            },
            "severe": {
                "suggestion": "Work on strengthening your core and back muscles. Practice presentations standing against a wall to develop awareness of proper alignment.",
                "impact": "Consistent slouching substantially undermines your credibility and presence."
            }
        },
        "Eye Contact": {
            "mild": {
                "suggestion": "Try to look more directly at the camera or audience. Place a visual reminder near the camera if presenting virtually.",
                "impact": "Occasional lack of eye contact slightly reduces engagement."
            },
            "moderate": {
                "suggestion": "Practice maintaining eye contact by placing notes higher up or using visual cues at eye level. Record yourself to check your eye contact patterns.",
                "impact": "Inconsistent eye contact makes it harder to connect with your audience."
            },
            "severe": {
                "suggestion": "Deliberately practice maintaining eye contact in conversations. When presenting, divide the audience into sections and make eye contact with each section systematically.",
                "impact": "Poor eye contact significantly reduces audience engagement and perceived sincerity."
            }
        },
        "Rigid Posture": {
            "mild": {
                "suggestion": "Try to incorporate slight natural movements in your posture. Gentle weight shifts can help you appear more relaxed.",
                "impact": "Slightly rigid posture can make you appear a bit formal or nervous."
            },
            "moderate": {
                "suggestion": "Practice deliberately incorporating natural movement into your presentations. Breathing exercises before presenting can help reduce tension.",
                "impact": "Consistent rigidity makes you appear uncomfortable and reduces your expressiveness."
            },
            "severe": {
                "suggestion": "Work on relaxation techniques before presenting. Practice moving naturally while speaking, and consider movement exercises to reduce physical tension.",
                "impact": "Extreme rigidity makes you appear highly uncomfortable and significantly limits your ability to engage the audience."
            }
        },
        "Excessive Movement": {
            "mild": {
                "suggestion": "Try to be more deliberate with your movements. Anchoring yourself in a comfortable stance can help reduce unnecessary movement.",
                "impact": "Occasional excessive movement is slightly distracting."
            },
            "moderate": {
                "suggestion": "Practice staying more grounded during presentations. Use deliberate movements to emphasize points rather than continuous motion.",
                "impact": "Frequent unnecessary movement distracts from your message and can signal nervousness."
            },
            "severe": {
                "suggestion": "Work on staying in one place with feet approximately shoulder-width apart. Practice presenting while standing on a small mat or defined area to limit movement.",
                "impact": "Continuous movement seriously distracts the audience and undermines your appearance of confidence."
            }
        },
        "Hand Position": {
            "mild": {
                "suggestion": "Try to keep your hands visible and use them for natural gestures. Avoid keeping them in pockets or behind your back for extended periods.",
                "impact": "Occasionally hidden hands slightly reduce your expressiveness."
            },
            "moderate": {
                "suggestion": "Practice deliberate hand gestures that emphasize your points. Keep hands in the 'gesture box' area between your shoulders and waist.",
                "impact": "Frequently hidden or inactive hands significantly reduce your ability to emphasize points and convey confidence."
            },
            "severe": {
                "suggestion": "Work on incorporating purposeful hand gestures into your presentations. Record yourself presenting and analyze how you use your hands to communicate.",
                "impact": "Consistently poor hand positioning severely limits your nonverbal communication and can make you appear uncomfortable or unprepared."
            }
        }
    }
    
    # Determine severity based on percentage
    severity = "mild"
    if percentage > 50:
        severity = "severe"
    elif percentage > 30:
        severity = "moderate"
    
    # Get feedback for the specific issue and severity
    issue_feedback = feedback.get(issue_name, {}).get(severity, {})
    
    suggestion = issue_feedback.get("suggestion", 
        "Work on maintaining good posture throughout your presentation.")
    
    impact = issue_feedback.get("impact", 
        "This aspect of body language affects how your audience perceives you.")
    
    return suggestion, severity, impact

def calculate_score(issues):
    """Calculate a more nuanced score based on issues and their severity"""
    # Start with a base score
    score = 9.0
    
    # Define severity weights for score calculation
    severity_weights = {
        'Head Tilt': 0.8,
        'Forward Lean': 1.0,
        'Shoulder Imbalance': 0.7,
        'Slouching': 1.2,
        'Eye Contact': 1.5,
        'Rigid Posture': 0.6,
        'Excessive Movement': 1.0,
        'Hand Position': 0.9
    }
    
    # Calculate weighted deductions
    for issue in issues:
        issue_name = issue['issue']
        percentage = issue['percentage']
        
        # Deduct points based on severity
        weight = severity_weights.get(issue_name, 1.0)
        
        # Calculate deduction: 
        # - Mild issues (15-30%): small deduction
        # - Moderate issues (30-50%): medium deduction
        # - Severe issues (>50%): large deduction
        if percentage > 50:
            deduction = weight * 1.5
        elif percentage > 30:
            deduction = weight * 1.0
        else:
            deduction = weight * 0.5
            
        score -= deduction
    
    # Ensure score is between 3 and 10
    return max(3, min(10, round(score)))

def generate_posture_report(video_path, report_id):
    """
    Generate a simplified posture analysis report.
    
    Args:
        video_path: Path to the video file
        report_id: ID for the report
    """
    try:
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video file not found at path: {video_path}")

        # Create required directories
        report_dir = f"tmp/{report_id}/reports"
        os.makedirs(report_dir, exist_ok=True)
        
        # Run simplified analysis
        analysis_results = analyze_posture(video_path)
        
        # Save text report
        report_filename = f"{report_dir}/body_analysis.txt"
        with open(report_filename, 'w') as f:
            f.write("Body Language Analysis Report\n")
            f.write("===========================\n\n")
            f.write(f"Video: {video_path}\n")
            f.write(f"Detection rate: {analysis_results['detection_rate']:.1f}%\n")
            f.write(f"Overall score: {analysis_results['score']}/10\n\n")
            
            if 'error' in analysis_results:
                f.write(f"Note: {analysis_results['error']}\n\n")
                
            f.write("Key findings:\n")
            if analysis_results['issues']:
                for idx, issue in enumerate(analysis_results['issues'], 1):
                    f.write(f"{idx}. {issue['topic']}\n")
                    f.write(f"   Example: {issue['examples'][0]}\n")
                    f.write(f"   Suggestion: {issue['suggestions'][0]}\n\n")
            else:
                f.write("No significant posture issues detected.\n")
        
        # Update database with simplified results
        try:
            from services import storage_service
            
            update_data = {
                "scoreBodyLanguage": analysis_results['score'],
                "weaknessTopicsBodylan": analysis_results['issues']
            }
            
            # Debug logging to verify what's being sent to Supabase
            print(f"Updating Supabase with:")
            print(f"  Score: {update_data['scoreBodyLanguage']}")
            print(f"  Issues: {len(update_data['weaknessTopicsBodylan'])} items")
            
            # Execute the update
            response = storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
            
            # Log the response
            if response.data:
                print(f"Database update successful, updated {len(response.data)} records")
            else:
                print(f"Database update failed: {response.error}")
                
            logger.info(f"Database updated with body language score: {analysis_results['score']}")
        except Exception as e:
            logger.error(f"Failed to update database: {e}")
            print(f"Failed to update database: {e}")
        
        logger.info(f"Body language analysis completed for report {report_id}")
        return report_filename
    
    except Exception as e:
        logger.error(f"Error generating posture report: {e}")
        raise
