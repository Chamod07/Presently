from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service, pose_analysis_service
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Body Language Analysis"])

@router.get("/score")
async def get_body_language_score(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("scoreBodyLanguage") \
            .eq("reportId", report_id) \
            .execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Body language score not found")

        if "scoreBodyLanguage" not in response.data[0] or response.data[0]["scoreBodyLanguage"] is None:
            raise HTTPException(status_code=404, detail="Body language score not found")
        
        return {"scoreBodyLanguage": response.data[0]["scoreBodyLanguage"]}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.get("/weaknesses")
async def get_body_language_weaknesses(
    report_id: str = Query(..., description="Report ID"),
    user_id: str = Depends(get_current_user_id)):
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("weaknessTopicsBodylan") \
            .eq("reportId", report_id) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No body language weaknesses found")

        if "weaknessTopicsBodylan" not in response.data[0] or response.data[0]["weaknessTopicsBodylan"] is None:
            raise HTTPException(status_code=404, detail="No body language weaknesses found")

        return {"weaknessTopics": response.data[0]["weaknessTopicsBodylan"]}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.post("/analyze_video")
async def analyze_video(report_id: str = Query(...), video_path: str = Query(None)):
    """
    Analyze body language from video using simplified approach.
    
    Parameters:
    - report_id: ID of the report to update
    - video_path: Optional path to the downloaded video file
    
    Returns:
    - A status message indicating success
    """
    try:
        print("\n" + "-" * 60)
        print(f"BODY LANGUAGE ANALYSIS: Starting for report {report_id}")
        print("-" * 60)
        
        # If video_path is not provided, use standard location
        if not video_path:
            video_path = f"tmp/{report_id}/video/video.mp4"
            print(f"[1/3] Using standard video path: {video_path}")
        else:
            print(f"[1/3] Using provided video path: {video_path}")
        
        # Check if video file exists
        if not os.path.exists(video_path):
            print(f"✗ Error: Video file not found at: {video_path}")
            logger.error(f"Video file not found: {video_path}")
            raise HTTPException(status_code=404, detail=f"Video file not found at: {video_path}")
        
        # Generate simplified body language report
        print(f"[2/3] Analyzing body language...")
        try:
            report_file = pose_analysis_service.generate_posture_report(video_path, report_id)
            print(f"[3/3] Saving analysis results...")
            print(f"✓ BODY LANGUAGE ANALYSIS: Completed for report {report_id}")
        except Exception as e:
            print(f"✗ Error analyzing body language: {str(e)}")
            raise
            
        print("-" * 60 + "\n")
        
        return {"status": "success", "message": "Body language analysis complete", "report_file": report_file}
        
    except Exception as e:
        logger.error(f"Body language analysis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Body language analysis failed: {str(e)}")
