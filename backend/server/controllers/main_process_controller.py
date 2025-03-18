from fastapi import APIRouter, HTTPException, Query
import os
from supabase import create_client, Client
import logging

# Import needed controller functions directly
from controllers.audio_process_controller import convert_to_mp3, transcribe_audio
from controllers.body_language_analysis_controller import analyze_video
from controllers.context_analysis_controller import analyze_context
from controllers.grammar_analysis_controller import analyze_grammar

# Set up logging
logger = logging.getLogger(__name__)
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
        logger.info(f"Starting video processing for report {report_id}")
        
        # 1. Download video from Supabase storage
        local_video_path = await download_from_supabase(video_url, report_id)
        logger.info(f"Video downloaded to {local_video_path}")
        
        # 2. Convert to MP3
        audio_path = await convert_to_mp3(report_id=report_id, video_path=local_video_path)
        logger.info(f"Converted video to audio: {audio_path}")
        
        # 3. Transcribe
        transcription_result = await transcribe_audio(report_id=report_id)
        transcription = transcription_result["transcription"]
        logger.info(f"Transcription complete: {len(transcription)} characters")
        
        # 4. Analyze body language
        body_language_result = await analyze_video(report_id=report_id, video_path=local_video_path)
        logger.info("Body language analysis complete")
        
        # 5. Analyze context
        context_result = await analyze_context(transcription=transcription, report_id=report_id)
        logger.info("Context analysis complete")
        
        # 6. Analyze grammar
        grammar_result = await analyze_grammar(transcription=transcription, report_id=report_id)
        logger.info("Grammar analysis complete")
        
        return {
            "message": "Video processed and analyzed successfully.",
            "report_id": report_id
        }
    except Exception as e:
        logger.error(f"Error processing video: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def download_from_supabase(video_url: str, report_id: str) -> str:
    """Download video from Supabase storage to local temp directory"""
    try:
        # Extract path from URL
        # The video_url will look like: https://supabase-url.storage.googleapis.com/bucket/user_123/presentation_456/video_456.mp4
        path_parts = video_url.split('/')
        bucket_name = 'videos'  # Bucket name from camera_function.dart
        
        # Find bucket index in path
        if bucket_name not in path_parts:
            raise HTTPException(status_code=400, detail=f"Invalid video URL format: bucket '{bucket_name}' not found")
        
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
        logger.error(f"Failed to download video: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to download video from storage: {str(e)}")
