from fastapi import APIRouter, HTTPException, Query
import os
from supabase import create_client, Client
import logging
import httpx
from urllib.parse import urlparse, unquote

# Import the correct audio processing services
from services.audio_processing import convert_video_to_mp3, transcribe_audio_to_text

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
    errors = []  # Track errors but continue processing
    
    try:
        logger.info(f"Starting video processing for report {report_id}")
        
        # 1. Download video from Supabase storage
        local_video_path = await download_from_supabase(video_url, report_id)
        logger.info(f"Video downloaded to {local_video_path}")
        
        # 2. Convert to MP3 - direct service call
        try:
            audio_path = convert_video_to_mp3(report_id, local_video_path)
            logger.info(f"Converted video to audio: {audio_path}")
        except Exception as e:
            error_msg = f"Audio conversion failed: {str(e)}"
            logger.error(error_msg)
            errors.append(error_msg)
            audio_path = None
        
        # 3. Transcribe - direct service call
        transcription = ""
        try:
            if audio_path:
                transcription = transcribe_audio_to_text(report_id)
                logger.info(f"Transcription complete: {len(transcription)} characters")
        except Exception as e:
            error_msg = f"Transcription failed: {str(e)}"
            logger.error(error_msg)
            errors.append(error_msg)
            logger.warning("Proceeding with empty transcription")
        
        # 4. Analyze body language
        try:
            from controllers.body_language_analysis_controller import analyze_video
            body_language_result = await analyze_video(report_id=report_id, video_path=local_video_path)
            logger.info("Body language analysis complete")
        except Exception as e:
            error_msg = f"Body language analysis failed: {str(e)}"
            logger.error(error_msg)
            errors.append(error_msg)
        
        # 5. Analyze context
        if transcription:
            try:
                from controllers.context_analysis_controller import analyze_context
                context_result = await analyze_context(transcription=transcription, report_id=report_id)
                logger.info("Context analysis complete")
            except Exception as e:
                error_msg = f"Context analysis failed: {str(e)}"
                logger.error(error_msg)
                errors.append(error_msg)
        
        # 6. Analyze grammar
        if transcription:
            try:
                from controllers.grammar_analysis_controller import analyze_grammar
                grammar_result = await analyze_grammar(transcription=transcription, report_id=report_id)
                logger.info("Grammar analysis complete")
            except Exception as e:
                error_msg = f"Grammar analysis failed: {str(e)}"
                logger.error(error_msg)
                errors.append(error_msg)
        
        # Return results with any errors that occurred
        if errors:
            return {
                "message": "Video processed with some errors",
                "report_id": report_id,
                "errors": errors
            }
        else:
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
        # Parse URL and remove query parameters
        parsed_url = urlparse(video_url)
        
        # Extract the actual filename without query parameters
        file_name = "video.mp4"  # Standardized file name
        
        # Create standardized temporary directory structure
        temp_dir = f"tmp/{report_id}/video"
        os.makedirs(temp_dir, exist_ok=True)
        local_file_path = f"{temp_dir}/{file_name}"
        
        logger.info(f"Downloading video URL: {video_url}")
        logger.info(f"Saving to: {local_file_path}")
        
        # For direct download from signed URL
        async with httpx.AsyncClient() as client:
            response = await client.get(video_url)
            if response.status_code == 200:
                with open(local_file_path, 'wb') as f:
                    f.write(response.content)
                logger.info(f"Video downloaded successfully to {local_file_path}")
                return local_file_path
            else:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Failed to download video: HTTP {response.status_code}"
                )
                
    except Exception as e:
        logger.error(f"Failed to download video: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to download video from storage: {str(e)}")
