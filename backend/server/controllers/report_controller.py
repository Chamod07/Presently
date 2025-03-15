from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service
import logging

router = APIRouter(tags=["Report"])

@router.get("")
async def get_complete_report(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    """
    Get complete report data including context, grammar, body language and voice analysis
    in a single API call
    """
    try:
        # Fetch all report data at once
        response = storage_service.supabase.table("UserReport").select(
            "scoreContext",
            "weaknessTopicsContext",
            "scoreGrammar",
            "weaknessTopicsGrammar",
            "scoreBodyLanguage",
            "weaknessTopicsBodylan",
            "scoreVoice",
            "weaknessTopicsVoice"
        ).eq("reportId", report_id).execute()
        
        if not response.data or len(response.data) == 0:
            raise HTTPException(status_code=404, detail="Report not found")
            
        report_data = response.data[0]
        
        # Format response to match frontend model structure
        formatted_response = {
            "context": {
                "overall_score": report_data.get("scoreContext"),
                "weakness_topics": report_data.get("weaknessTopicsContext", [])
            },
            "grammar": {
                "grammar_score": report_data.get("scoreGrammar"),
                "weakness_topics": report_data.get("weaknessTopicsGrammar", [])
            },
            "bodyLanguage": {
                "scoreBodyLanguage": report_data.get("scoreBodyLanguage"),
                "weaknessTopics": report_data.get("weaknessTopicsBodylan", [])
            },
            "voice": {
                "scoreVoice": report_data.get("scoreVoice"),
                "weaknessTopics": report_data.get("weaknessTopicsVoice", [])
            }
        }
        
        return formatted_response
        
    except Exception as e:
        logging.error(f"Error fetching complete report: {e}")
        raise HTTPException(status_code=500, detail=f"Error retrieving report data: {str(e)}")
