from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service

router = APIRouter(tags=["Voice Analysis"])

@router.get("/score")
async def get_voice_score(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    
    response = storage_service.supabase.table("UserReport") \
        .select("scoreVoice") \
        .eq("reportId", report_id) \
        .execute()
    
    if not response.data:
        raise HTTPException(status_code=404, detail="Voice score not found")
    
    return {"scoreVoice": response.data[0]["scoreVoice"]}

@router.get("/weaknesses")
async def get_voice_weaknesses(
    report_id: str = Query(..., description="Report ID"),
    user_id: str = Depends(get_current_user_id)):
    
    response = storage_service.supabase.table("UserReport") \
        .select("weaknessTopicsVoice") \
        .eq("reportId", report_id) \
        .execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No voice weaknesses found")

    return {"weaknessTopics": response.data[0]["weaknessTopicsVoice"]}
