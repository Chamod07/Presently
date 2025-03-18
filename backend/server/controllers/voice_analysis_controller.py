from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Voice Analysis"])

@router.get("/score")
async def get_voice_score(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("scoreVoice") \
            .eq("reportId", report_id) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Voice score not found")

        # Check if 'scoreVoice' key exists and has a valid value
        if "scoreVoice" not in response.data[0] or response.data[0]["scoreVoice"] is None:
          raise HTTPException(status_code=404, detail="Voice score not found")
        
        return {"scoreVoice": response.data[0]["scoreVoice"]}
    except Exception as e:
        # Catch any other exceptions, log them, and raise a generic 500 error
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")


@router.get("/weaknesses")
async def get_voice_weaknesses(
    report_id: str = Query(..., description="Report ID"),
    user_id: str = Depends(get_current_user_id)):
    
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("weaknessTopicsVoice") \
            .eq("reportId", report_id) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No voice weaknesses found")

        # Check if 'weaknessTopicsVoice' key exists and has a valid value
        if "weaknessTopicsVoice" not in response.data[0] or response.data[0]["weaknessTopicsVoice"] is None:
            raise HTTPException(status_code=404, detail="No voice weaknesses found")


        return {"weaknessTopics": response.data[0]["weaknessTopicsVoice"]}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")
