import numpy as np
from collections import deque

def analyze_presenter_movement(pose_history, frame_count, frame_rate):
    """Analyze presenter's movement patterns and use of space."""
    if len(pose_history) < 2:
        return None
    
    # Calculate movement metrics
    position_changes = []
    for i in range(1, len(pose_history)):
        prev_pos = pose_history[i-1]
        curr_pos = pose_history[i]
        
        # Calculate position change of center point (between hips)
        if 'hip_center' in prev_pos and 'hip_center' in curr_pos:
            movement = np.linalg.norm(
                np.array(curr_pos['hip_center']) - np.array(prev_pos['hip_center'])
            )
            position_changes.append(movement)
    
    if not position_changes:
        return None
        
    # Average movement per frame
    avg_movement = np.mean(position_changes)
    
    # Classify movement patterns
    movement_intensity = "low"
    if avg_movement > 0.01:  # Threshold depends on normalization
        movement_intensity = "moderate"
    if avg_movement > 0.03:
        movement_intensity = "high"
        
    # Check for pacing (rhythmic movement)
    movement_pattern = "stable"
    if len(position_changes) > frame_rate * 5:  # Need at least 5 seconds
        # Detect rhythmic movement using autocorrelation
        autocorr = np.correlate(position_changes, position_changes, mode='full')
        autocorr = autocorr[len(autocorr)//2:]
        
        if np.max(autocorr[1:]) > 0.7 * autocorr[0]:
            movement_pattern = "pacing"
    
    movement_data = {
        'avg_movement': avg_movement,
        'movement_intensity': movement_intensity,
        'movement_pattern': movement_pattern,
        'frame': frame_count
    }
    
    return movement_data
