from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service, pose_analysis_service
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
async def analyze_video(report_id: str = Query(...)):
    try:
        report_path = pose_analysis_service.generate_posture_report(f'res/video/{report_id}_video.mp4',report_id)
        return {"report_path": report_path}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
