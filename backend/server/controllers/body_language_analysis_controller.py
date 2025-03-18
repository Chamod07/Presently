from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service, pose_analysis_service

router = APIRouter(tags=["Body Language Analysis"])

@router.get("/score")
async def get_body_language_score(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    response = storage_service.supabase.table("UserReport") \
        .select("scoreBodyLanguage") \
        .eq("reportId", report_id) \
        .execute()
    
    if not response.data:
        raise HTTPException(status_code=404, detail="Body language score not found")
    
    return {"scoreBodyLanguage": response.data[0]["scoreBodyLanguage"]}

@router.get("/weaknesses")
async def get_body_language_weaknesses(
    report_id: str = Query(..., description="Report ID"),
    user_id: str = Depends(get_current_user_id)):
    
    response = storage_service.supabase.table("UserReport") \
        .select("weaknessTopicsBodylan") \
        .eq("reportId", report_id) \
        .execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No body language weaknesses found")

    return {"weaknessTopics": response.data[0]["weaknessTopicsBodylan"]}

@router.post("/analyze_video")
async def analyze_video(report_id: str = Query(...)):
    try:
        report_path = pose_analysis_service.generate_posture_report(f'res/video/{report_id}_video.mp4',report_id)
        return {"report_path": report_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
