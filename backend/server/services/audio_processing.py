import subprocess
import os
import logging
import shutil
from fastapi import HTTPException
from services.whisper_service import transcribe_audio

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def convert_video_to_mp3(report_id, video_path=None):
    """
    Convert video to MP3 format.
    
    Args:
        report_id: The report ID to use for generating output paths
        video_path: Optional explicit path to the video file. If not provided,
                   the function will look for a video in a standardized location
    
    Returns:
        Path to the converted MP3 file
    """
    # Improved logging for debugging
    logging.info(f"Converting video to MP3 for report {report_id}")
    
    # Standardized directory structure
    video_dir = f"tmp/{report_id}/video"
    audio_dir = f"tmp/{report_id}/audio"
    
    # Create audio directory
    os.makedirs(audio_dir, exist_ok=True)
    
    # Standard output path
    output_audio_path = f"{audio_dir}/audio.mp3"
    
    # If video_path is provided, use it directly
    if video_path and os.path.exists(video_path):
        input_video_path = video_path
        logging.info(f"Using provided video path: {video_path}")
    else:
        # Use standard video path
        input_video_path = f"{video_dir}/video.mp4"
        logging.info(f"Using standard video path: {input_video_path}")
        
        if not os.path.exists(input_video_path):
            # Try to find any video file in the directory
            if os.path.exists(video_dir):
                video_files = [f for f in os.listdir(video_dir) if f.endswith(('.mp4', '.mov', '.avi', '.mkv'))]
                if video_files:
                    input_video_path = f"{video_dir}/{video_files[0]}"
                    logging.info(f"Found alternative video file: {input_video_path}")
                else:
                    raise FileNotFoundError(f"No video files found in {video_dir}")
            else:
                raise FileNotFoundError(f"Video directory not found: {video_dir}")
    
    # Execute ffmpeg command to convert video to MP3
    try:
        ffmpeg_cmd = [
            "ffmpeg", "-y", "-i", input_video_path,  # Add -y to force overwrite
            "-vn",  # No video
            "-ar", "44100",  # Audio sampling rate
            "-ac", "2",  # Audio channels
            "-ab", "192k",  # Audio bitrate
            "-f", "mp3",  # Output format
            output_audio_path
        ]
        
        # Log the command for debugging
        logging.info(f"Running FFMPEG command: {' '.join(ffmpeg_cmd)}")
        
        # Run the command with more detailed output
        result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            logging.error(f"FFMPEG error (code {result.returncode}): {result.stderr}")
            raise Exception(f"Failed to convert video to MP3: {result.stderr}")
        
        logging.info(f"FFMPEG conversion successful, output at: {output_audio_path}")
        
        # Copy to transcription directory for consistency
        transcription_dir = f"tmp/{report_id}/transcription"
        os.makedirs(transcription_dir, exist_ok=True)
        
        return output_audio_path
        
    except Exception as e:
        logging.error(f"Error converting video to MP3: {str(e)}")
        raise

def transcribe_audio_to_text(report_id: str):
    try:
        # Use standardized path
        audio_dir = f"tmp/{report_id}/audio"
        audio_file_path = f"{audio_dir}/audio.mp3"
        
        # Check if audio file exists
        if not os.path.exists(audio_file_path):
            raise FileNotFoundError(f"Audio file not found at {audio_file_path}")
        
        # Transcribe the audio
        transcription, _ = transcribe_audio(audio_file_path)
        
        if not transcription:
            raise HTTPException(status_code=404, detail="Transcription failed or returned empty.")
        
        # Save transcription to standard location
        transcription_dir = f"tmp/{report_id}/transcription"
        os.makedirs(transcription_dir, exist_ok=True)
        output_file = f"{transcription_dir}/transcription.txt"
        
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(transcription)
        
        logger.info(f"Transcription saved to '{output_file}'.")
        
        return transcription
        
    except Exception as e:
        # Handle other potential errors
        logger.error(f"An error occurred during transcription: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
