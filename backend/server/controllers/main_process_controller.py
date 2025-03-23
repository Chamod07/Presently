from fastapi import APIRouter, HTTPException, Query
import os
from supabase import create_client, Client
import logging
import httpx
from urllib.parse import urlparse, unquote

# Import the correct audio processing services
from services.audio_processing import convert_video_to_mp3, transcribe_audio_to_text
# Import the task assignment controller
from controllers.task_assign_controller import assign_challenges_endpoint

# Set up standard logging
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
        # Better step logging with visual separators
        print("\n" + "=" * 60)
        print(f"STARTING PROCESS: Video analysis for report {report_id}")
        print("=" * 60)
        
        logger.info(f"Starting video processing for report {report_id}")
        
        # 1. Download video from Supabase storage
        print("\n[STEP 1/8] Downloading video from URL...")
        local_video_path = await download_from_supabase(video_url, report_id)
        print(f"✓ Video downloaded to {local_video_path}")
        
        # 2. Convert to MP3 - direct service call
        try:
            print("\n[STEP 2/8] Converting video to audio...")
            audio_path = convert_video_to_mp3(report_id, local_video_path)
            print(f"✓ Converted video to audio: {audio_path}")
        except Exception as e:
            error_msg = f"Audio conversion failed: {str(e)}"
            print(f"✗ Audio conversion error: {str(e)}")
            logger.error(error_msg)
            errors.append(error_msg)
            audio_path = None
        
        # 3. Transcribe - direct service call
        transcription = ""
        try:
            if audio_path:
                print("\n[STEP 3/8] Transcribing audio...")
                transcription = transcribe_audio_to_text(report_id)
                print(f"✓ Transcription complete: {len(transcription)} characters")
        except Exception as e:
            error_msg = f"Transcription failed: {str(e)}"
            print(f"✗ Transcription error: {str(e)}")
            logger.error(error_msg)
            errors.append(error_msg)
            print("! Warning: Proceeding with empty transcription")
        
        # 4. Analyze body language
        try:
            print("\n[STEP 4/8] Analyzing body language...")
            from controllers.body_language_analysis_controller import analyze_video
            body_language_result = await analyze_video(report_id=report_id, video_path=local_video_path)
            print(f"✓ Body language analysis complete")
        except Exception as e:
            error_msg = f"Body language analysis failed: {str(e)}"
            print(f"✗ Body language analysis error: {str(e)}")
            logger.error(error_msg)
            errors.append(error_msg)
        
        # 5. Analyze context
        if transcription:
            print("\n[STEP 5/8] Analyzing context...")
            try:
                from controllers.context_analysis_controller import analyze_context
                context_result = await analyze_context(transcription=transcription, report_id=report_id)
                print(f"✓ Context analysis complete")
            except Exception as e:
                error_msg = f"Context analysis failed: {str(e)}"
                print(f"✗ Context analysis error: {str(e)}")
                logger.error(error_msg)
                errors.append(error_msg)
        else:
            print("\n! Warning: Skipping context analysis - no transcription available")
            
        # 6. Analyze grammar
        if transcription:
            print("\n[STEP 6/8] Analyzing grammar...")
            try:
                from controllers.grammar_analysis_controller import analyze_grammar
                grammar_result = await analyze_grammar(text=transcription, report_id=report_id)
                print(f"✓ Grammar analysis complete")
            except Exception as e:
                error_msg = f"Grammar analysis failed: {str(e)}"
                print(f"✗ Grammar analysis error: {str(e)}")
                logger.error(error_msg)
                errors.append(error_msg)
        else:
            print("\n! Warning: Skipping grammar analysis - no transcription available")
        
        # 7. Analyze voice characteristics
        if audio_path:
            print("\n[STEP 7/8] Analyzing voice...")
            try:
                from controllers.voice_analysis_controller import analyze_voice
                voice_result = await analyze_voice(report_id=report_id)
                print(f"✓ Voice analysis complete")
            except Exception as e:
                error_msg = f"Voice analysis failed: {str(e)}"
                print(f"✗ Voice analysis error: {str(e)}")
                logger.error(error_msg)
                errors.append(error_msg)
        else:
            print("\n! Warning: Skipping voice analysis - no audio file available")
        
        # 8. Assign challenges based on analysis
        print("\n[STEP 8/8] Assigning tasks...")
        try:
            challenge_assignment = await assign_challenges_endpoint(report_id=report_id)
            print(f"✓ Tasks assigned successfully")
        except Exception as e:
            error_msg = f"Task assignment failed: {str(e)}"
            print(f"✗ Task assignment error: {str(e)}")
            logger.error(error_msg)
            errors.append(error_msg)
            
        # Return results with any errors that occurred
        print("\n" + "=" * 60)
        if errors:
            print(f"PROCESS COMPLETED WITH {len(errors)} ERRORS:")
            for i, error in enumerate(errors, 1):
                print(f"  Error {i}: {error}")
        else:
            print("PROCESS COMPLETED SUCCESSFULLY!")
        print("=" * 60 + "\n")
        
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
        print(f"\n✗ CRITICAL ERROR: {str(e)}")
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
