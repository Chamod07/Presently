from fastapi import APIRouter, HTTPException, Query
import subprocess
import os
from services.whisper_service import transcribe_audio

router = APIRouter()

@router.post("/convert_to_mp3")
async def convert_to_mp3(report_id: str = Query(...)):
    try:
        # Define input and output file paths
        input_video_path = "res/video/temp_video.mp4"
        output_audio_path = "res/audio/converted_audio.mp3"
        
        #create directories if they don't exist
        os.makedirs(os.path.dirname(output_audio_path), exist_ok=True)

        # Construct the FFmpeg command
        command = [
            "ffmpeg",
            "-i", input_video_path,
            output_audio_path
        ]

        # Execute the command
        result = subprocess.run(command, capture_output=True, text=True, check=True)


        # Return success message
        return {"message": f"Successfully converted video to MP3. File saved at: {output_audio_path}"}

    except subprocess.CalledProcessError as e:
        # Handle FFmpeg errors
        print(f"FFmpeg error: {e.stderr}")
        raise HTTPException(status_code=500, detail=f"FFmpeg conversion failed: {e.stderr}")
    except Exception as e:
        # Handle other potential errors
        print(f"An error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/transcribe")
async def transcribe(report_id: str = Query(...)):
    try:
        # Define the audio file path
        audio_file_path = "res/audio/converted_audio.mp3"

        # Transcribe the audio
        transcription, _ = transcribe_audio(audio_file_path)

        if not transcription:
            raise HTTPException(status_code=404, detail="Transcription failed or returned empty.")

        output_file = "res/transcription/transcription.txt"
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(transcription)
        print(f"Transcription saved to '{output_file}'.")

        # Return the transcription
        return {"transcription": transcription}

    except Exception as e:
        # Handle other potential errors
        print(f"An error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
