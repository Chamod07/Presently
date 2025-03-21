from fastapi import APIRouter, HTTPException, Request, Depends, Query
from services.auth_service import get_current_user_id
from services.gemini_context_service import GeminiContextAnalyzer
import uuid
from models.user_report_model import UserReport
from services import storage_service
import datetime
from fastapi import status
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
analyzer = GeminiContextAnalyzer()

@router.post("/analyze")
async def analyze_context(transcription: str, report_id: str):
    """
    Analyze the context and content of a presentation transcription.
    
    Args:
        transcription: The text transcription of the presentation
        report_id: The ID of the report to update
        
    Returns:
        A message indicating successful analysis
    """
    try:
        # Better step logging with visual separators
        print("\n" + "-" * 60)
        print(f"CONTEXT ANALYSIS: Starting for report {report_id}")
        print("-" * 60)
        
        logger.info(f"Analyzing context for report ID: {report_id}")
        
        # Check if transcription is valid
        if not transcription or len(transcription.strip()) < 10:
            print("✗ Error: Transcription is too short or empty")
            raise HTTPException(status_code=400, detail="Transcription is too short or empty")
        
        # Get session data for better context analysis
        try:
            session_data = analyzer.get_session_data(report_id)
        except Exception as e:
            print(f"! Warning: Error retrieving session data: {str(e)}")
            logger.warning(f"Session data retrieval error: {str(e)}")
            session_data = {
                'session_topic': 'General presentation',
                'session_type': 'Unknown',
                'session_goal': 'Information delivery',
                'audience': 'General audience'
            }
        
        # Use the session topic from the session data
        topic = session_data.get('session_topic', 'unknown')
        
        print(f"[1/3] Processing {len(transcription)} characters of text for topic '{topic}'...")
        print(f"      Session context: Type={session_data.get('session_type', 'Unknown')}, Goal={session_data.get('session_goal', 'Unknown')}")
        print(f"                       Audience={session_data.get('audience', 'Unknown')}, Topic={session_data.get('session_topic', 'Unknown')}")
            
        # Call the Gemini service to analyze context with session data
        print(f"[2/3] Running context analysis with AI...")
        context_results = analyzer.analyze_presentation(
            transcription=transcription, 
            report_id=report_id,
            session_data=session_data
        )
        
        # Format the results for storage
        score = context_results.get("score", 0)
        weaknesses = context_results.get("weaknesses", [])
        
        print(f"[2/3] Analysis results: Score {score}/10 with {len(weaknesses)} identified issues")
        
        # Update the database with results
        print(f"[3/3] Saving results to database...")
        update_data = {
            "scoreContext": score,
            "weaknessTopicsContext": weaknesses
        }
        
        storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
        
        print(f"✓ CONTEXT ANALYSIS: Completed for report {report_id}")
        print("-" * 60 + "\n")
        
        return {
            "message": "Context analysis completed successfully",
            "score": score,
            "weaknesses_count": len(weaknesses)
        }
        
    except HTTPException as e:
        # Re-raise HTTP exceptions
        print(f"✗ CONTEXT ANALYSIS ERROR: {e.detail}")
        raise
    except Exception as e:
        print(f"✗ CONTEXT ANALYSIS ERROR: {str(e)}")
        logger.error(f"Context analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Context analysis failed: {str(e)}")

@router.get("/score")
async def get_overall_score(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the overall score of a specific analysis by Report ID"""
    try:
        response = storage_service.supabase.table("UserReport").select("scoreContext").eq("reportId", report_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")
        
        if "scoreContext" not in response.data[0] or response.data[0]["scoreContext"] is None:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

        overall_score = response.data[0]["scoreContext"]
        return {"overall_score": overall_score, "user_id": user_id}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.get("/sub_scores")
async def get_summery_score(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the content analysis scores of a specific analysis by Report ID"""
    try:
        response = storage_service.supabase.table("UserReport").select("subScoresContext").eq("reportId", report_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")
        
        if "subScoresContext" not in response.data[0] or response.data[0]["subScoresContext"] is None:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

        sub_scores_context = response.data[0]["subScoresContext"]
        print("\nReturning Content Analysis:", sub_scores_context)
        return {"content_analysis": sub_scores_context}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.get("/weaknesses")
async def get_weaknesses(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the weakness analysis from a specific analysis by Report ID"""
    try:
        response = storage_service.supabase.table("UserReport").select("weaknessTopicsContext").eq("reportId", report_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

        if "weaknessTopicsContext" not in response.data[0] or response.data[0]["weaknessTopicsContext"] is None:
            raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

        weakness_topics_context = response.data[0]["weaknessTopicsContext"]
        #print("\nReturning Weaknesses:", weakness_topics_context)
        return {"weakness_topics": weakness_topics_context}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.get("/reports")
async def list_reports(limit: int = Query(10, title="Limit"), offset: int = Query(0, title="Offset"), user_id: str = Depends(get_current_user_id)):
    """List all reports with pagination"""
    try:
        response = storage_service.supabase.table("UserReport").select("*").range(offset, offset + limit - 1).execute()

        if response.error:
            raise HTTPException(status_code=500, detail=response.error)

        return response.data
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.delete("/report/delete/{reportId}")
async def delete_report(reportId: str, user_id: str = Depends(get_current_user_id)):
    """Remove a report"""
    try:
        response = storage_service.supabase.table("UserReport").delete().eq("reportId", reportId).execute()

        if response.error:
            raise HTTPException(status_code=500, detail=response.error)

        return {"message": f"Report with reportId {reportId} deleted successfully"}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

    #confirmation needs to be added.

@router.get("/health")
async def health_check_context(user_id: str = Depends(get_current_user_id)):
    """Check if the API is running"""
    return {"status": "healthy"}
