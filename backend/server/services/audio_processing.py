import subprocess
import os
import logging
from fastapi import HTTPException
from services.whisper_service import transcribe_audio

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def convert_video_to_mp3(report_id: str):
    try:
        # Define input and output file paths
        input_video_path = f"res/video/{report_id}_video.mp4"
        output_audio_path = f"res/audio/{report_id}_audio.mp3"
        
        #create directories if they don't exist
        os.makedirs(os.path.dirname(output_audio_path), exist_ok=True)

        # Construct the FFmpeg command
        command = [
            "ffmpeg",
            "-i", input_video_path,
            output_audio_path
        ]

        # Execute the command
        subprocess.run(command, capture_output=True, text=True, check=True)
        logger.info(f"Successfully converted video to MP3. File saved at: {output_audio_path}")
        return output_audio_path

    except subprocess.CalledProcessError as e:
        # Handle FFmpeg errors
        logger.error(f"FFmpeg error: {e.stderr}")
        raise HTTPException(status_code=500, detail=f"FFmpeg conversion failed: {e.stderr}")
    except Exception as e:
        # Handle other potential errors
        logger.error(f"An error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

def transcribe_audio_to_text(report_id: str):
    try:
        # Define the audio file path
        audio_file_path = f"res/audio/{report_id}_audio.mp3"

        # Transcribe the audio
        transcription, _ = transcribe_audio(audio_file_path)

        if not transcription:
            raise HTTPException(status_code=404, detail="Transcription failed or returned empty.")

        output_file = f"res/transcription/{report_id}_transcription.txt"
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(transcription)
        logger.info(f"Transcription saved to '{output_file}'.")

        return transcription

    except Exception as e:
        # Handle other potential errors
        logger.error(f"An error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
