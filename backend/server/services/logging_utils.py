import os
import sys
import io
import logging
import contextlib
import warnings

# Basic warning suppression - keeping only essential ones
warnings.filterwarnings('ignore')

# Keep only essential environment variables
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['MEDIAPIPE_DISABLE_GPU'] = '1'

@contextlib.contextmanager
def suppress_stdout_stderr():
    """
    Context manager to temporarily suppress stdout and stderr.
    Use this during MediaPipe operations that produce excessive logs.
    """
    # Save original stdout/stderr
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    
    # Create null device to swallow all output
    null_out = io.StringIO()
    null_err = io.StringIO()
    
    try:
        # Redirect stdout/stderr to null devices
        sys.stdout = null_out
        sys.stderr = null_err
        yield
    finally:
        # Restore stdout/stderr
        sys.stdout = old_stdout
        sys.stderr = old_stderr

# Initialize MediaPipe silently
def init_mediapipe():
    """
    Import and initialize MediaPipe with minimal logging suppression.
    Call this before any MediaPipe usage.
    """
    with suppress_stdout_stderr():
        import mediapipe as mp
        
        # Override MediaPipe's drawing utilities to do nothing (this helps reduce noise)
        def silent_draw_landmarks(*args, **kwargs):
            pass
        
        # Patch the original draw_landmarks function
        mp.solutions.drawing_utils.draw_landmarks = silent_draw_landmarks
        
        # Create a dummy DrawingSpec that does nothing
        mp.solutions.drawing_utils.DrawingSpec = lambda color=(0,0,0), thickness=0, circle_radius=0: None
        
        return mp
