from fastapi import APIRouter, HTTPException, Query
import httpx
import os
from supabase import create_client, Client

router = APIRouter()

# Initialize Supabase client
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(supabase_url, supabase_key)

@router.post("/")
async def process_video(video_url: str, report_id: str = Query(...)):
    """
    Process video and generate complete analysis by coordinating all analysis services.
    """
    try:
        # 1. Download video from Supabase storage
        local_video_path = await download_from_supabase(video_url, report_id)
        
        async with httpx.AsyncClient() as client:
            # 2. Convert to MP3
            convert_url = f"http://localhost:8000/api/process/audio/convert_to_mp3?report_id={report_id}&video_path={local_video_path}"
            convert_response = await client.post(convert_url)
            convert_response.raise_for_status()

            # 3. Transcribe
            transcribe_url = f"http://localhost:8000/api/process/audio/transcribe?report_id={report_id}"
            transcribe_response = await client.post(transcribe_url)
            transcribe_response.raise_for_status()
            transcription = transcribe_response.json()["transcription"]

            # 4. Analyze body language (posture + facial expressions + gestures + movement)
            body_language_url = f"http://localhost:8000/api/analyser/body-language/analyze_video?report_id={report_id}&video_path={local_video_path}"
            body_language_response = await client.post(body_language_url)
            body_language_response.raise_for_status()

            # 5. Analyze context
            context_analysis_url = "http://localhost:8000/api/analyser/context/analyze"
            context_payload = {"transcription": transcription, "reportId": report_id}
            context_response = await client.post(context_analysis_url, json=context_payload)
            context_response.raise_for_status()
            
            # 6. Analyze grammar
            grammar_analysis_url = "http://localhost:8000/api/analyser/grammar/analyze"
            grammar_payload = {"transcription": transcription, "reportId": report_id}
            grammar_response = await client.post(grammar_analysis_url, json=grammar_payload)
            grammar_response.raise_for_status()

            return {"message": "Video processed and analyzed successfully."}

    except httpx.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Request failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def download_from_supabase(video_url: str, report_id: str) -> str:
    """Download video from Supabase storage to local temp directory"""
    try:
        # Extract path from URL
        # The video_url will look like: https://supabase-url.storage.googleapis.com/bucket/user_123/presentation_456/video_456.mp4
        path_parts = video_url.split('/')
        bucket_name = 'videos'  # Bucket name from camera_function.dart
        
        # Get file name and directory components
        file_name = path_parts[-1]  # video_timestamp.mp4
        storage_path = '/'.join(path_parts[-(len(path_parts)-path_parts.index(bucket_name)-1):-1])  # user_X/presentation_Y
        
        # Create temporary directory
        temp_dir = f"tmp/videos/{report_id}"
        os.makedirs(temp_dir, exist_ok=True)
        local_file_path = f"{temp_dir}/{file_name}"
        
        # Download file from Supabase
        with open(local_file_path, 'wb+') as f:
            res = supabase.storage.from_(bucket_name).download(f"{storage_path}/{file_name}")
            f.write(res)
            
        return local_file_path
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to download video from storage: {str(e)}")
