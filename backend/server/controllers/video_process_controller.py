from fastapi import APIRouter, HTTPException, Query
import requests
import os
import uuid
from services import storage_service
import re

router = APIRouter()

@router.get("/download_video")
async def download_video(video_url: str, report_id: str = Query(...)):
    # Validate report_id format
    try:
        uuid.UUID(report_id, version=4)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid reportId format")

    # Check if report_id exists in Supabase
    report_exists = storage_service.supabase.table("UserReport").select("reportId").eq("reportId", report_id).execute()
    if not report_exists.data:
        raise HTTPException(status_code=404, detail="Report ID not found")

    # Basic URL validation
    if not re.match(r"^https?://", video_url):
        raise HTTPException(status_code=400, detail="Invalid video URL format")
    
    try:
        # Download the video file
        video_file = requests.get(video_url, stream=True)
        video_file.raise_for_status()

        # Check if the content is a video
        if 'video' not in video_file.headers.get('Content-Type', ''):
            raise HTTPException(status_code=415, detail="URL does not point to a video file")

        video_path = f"res/video/{report_id}_video.mp4"

        with open(video_path, "wb") as f:
            for chunk in video_file.iter_content(chunk_size=8192):
                f.write(chunk)

        return {"message": f"Successfully downloaded video. File saved at: {video_path}"}

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Failed to download video: {e}")
    except HTTPException as e:
        raise
