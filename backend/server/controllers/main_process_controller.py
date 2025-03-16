from fastapi import APIRouter, HTTPException, Query, Depends
import httpx
from services.auth_service import get_current_user_id
from services import storage_service

router = APIRouter()

@router.post("/process")
async def process_video(
    report_id: str = Query(...),
    user_id: str = Depends(get_current_user_id)
):
    try:
        # Get the video URL from the report
        response = storage_service.supabase.table("UserReport").select("videoUrl").eq("reportId", report_id).execute()
        
        if not response.data or not response.data[0].get("videoUrl"):
            raise HTTPException(status_code=404, detail="No video found for this report")
        
        video_url = response.data[0]["videoUrl"]
        
        async with httpx.AsyncClient() as client:
            # 1. Download video
            download_url = f"http://localhost:8000/api/process/video/download_video?video_url={video_url}&report_id={report_id}"
            download_response = await client.get(download_url)
            download_response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)

            # 2. Convert to MP3
            convert_url = f"http://localhost:8000/api/process/audio/convert_to_mp3?report_id={report_id}"
            convert_response = await client.post(convert_url)
            convert_response.raise_for_status()

            # 3. Transcribe
            transcribe_url = f"http://localhost:8000/api/process/audio/transcribe?report_id={report_id}"
            transcribe_response = await client.post(transcribe_url)
            transcribe_response.raise_for_status()
            transcription = transcribe_response.json()["transcription"]

            # 4. Analyze context
            context_analysis_url = "http://localhost:8000/api/analyser/context/analyze"
            context_payload = {"transcription": transcription, "reportId": report_id}
            context_response = await client.post(context_analysis_url, json=context_payload)
            context_response.raise_for_status()
            

            # 5. Analyze grammar
            grammar_analysis_url = "http://localhost:8000/api/analyser/grammar/analyze"
            grammar_payload = {"transcription": transcription, "reportId": report_id}
            grammar_response = await client.post(grammar_analysis_url, json=grammar_payload)
            grammar_response.raise_for_status()

            return {"message": "Video processed and analyzed successfully."}

    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Request failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
