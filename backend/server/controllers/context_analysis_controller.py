from fastapi import APIRouter, HTTPException, Request, Depends, Query
from services.auth_service import get_current_user_id
from services.gemini_context_service import GeminiContextAnalyzer
import uuid
from models.user_report_model import UserReport
from services import storage_service
import datetime
from typing import Dict
from fastapi import status
import logging

logger = logging.getLogger(__name__)

router = APIRouter()
analyzer = GeminiContextAnalyzer()

@router.post("/analyze")
async def analyze_presentation(request: Request):
    """Analyze a presentation transcription and store results in Supabase"""
    try:
        body = await request.json()
        transcription = body.get("transcription")
        report_id = body.get("reportId")
        topic = body.get("topic", "")

        if not transcription or not report_id:
            raise HTTPException(status_code=400, detail="transcription and reportId are required")

        try:
            uuid.UUID(report_id, version=4)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid reportId format")
        
        session_data = analyzer.retrieve_scenario_data(report_id)
        if not session_data:
            session_info = ""
        else:
            session_info = f"Session Type: {session_data.get('session_type', 'N/A')}, Goal: {session_data.get('session_goal', 'N/A')}, Audience: {session_data.get('audience', 'N/A')}"
            topic = session_data.get('topic') or topic

        analysis_results = analyzer.analyze_presentation(transcription, topic, session_info)


        user_report = UserReport(
            reportId=report_id,
            reportTopic=topic,
            scoreContext=analysis_results["overall_score"],
            subScoresContext=analysis_results["content_analysis"],
            weaknessTopicsContext=analysis_results["weakness_topics"],
            createdAt=datetime.datetime.now().isoformat()
        )
        data = user_report.dict()

        # Check if a report with the given reportId already exists
        existing_report = storage_service.supabase.table("UserReport").select("*").eq("reportId", report_id).execute()

        if existing_report.data:
            # Update only context-related fields
            update_data = {
                "scoreContext": analysis_results["overall_score"],
                "subScoresContext": analysis_results["content_analysis"],
                "weaknessTopicsContext": analysis_results["weakness_topics"],
               # "updatedAt": datetime.datetime.now().isoformat()
            }

            print(f"\nUpdating context fields for report {report_id}")
            response = storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
            print(f"Update result: {response.data}")
            if response.data and "error" in response.data:
                raise HTTPException(status_code=500, detail=response.data["error"])
            return {"message": f"Analysis completed successfully and updated report with reportId {report_id}"}
        else:
            # Insert a new report
            response = storage_service.supabase.table("UserReport").insert(data).execute()
            if response.data and "error" in response.data:
                raise HTTPException(status_code=500, detail=response.data["error"])
            return {"message": "Analysis completed successfully with new report id"}
    except Exception as e:
        logger.error(f"Error during analysis: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

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
