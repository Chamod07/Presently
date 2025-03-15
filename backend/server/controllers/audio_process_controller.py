from fastapi import APIRouter, HTTPException
import subprocess
import os

router = APIRouter()

@router.post("/convert_to_mp3")
async def convert_to_mp3():
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
