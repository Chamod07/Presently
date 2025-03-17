from fastapi import APIRouter, HTTPException, Query
import requests
import os

router = APIRouter()

@router.get("/download_video")
async def download_video(video_url: str, report_id: str = Query(...)):
    try:
        # Download the video file
        video_file = requests.get(video_url, stream=True)
        video_file.raise_for_status()

        video_path = "res/video/temp_video"
        file_extension = ".mp4"
        video_path += file_extension

        with open(video_path, "wb") as f:
            for chunk in video_file.iter_content(chunk_size=8192):
                f.write(chunk)

        return {"message": f"Successfully downloaded video. File saved at: {video_path}"}

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Failed to download video: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
