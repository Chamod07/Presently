from fastapi import APIRouter, HTTPException, Request, Depends, Query
from services.auth_service import get_current_user_id
from services.gemini_context_service import GeminiContextAnalyzer
import uuid
from models.user_report_model import UserReport
from services import storage_service
import datetime
from fastapi import status

router = APIRouter()
analyzer = GeminiContextAnalyzer()

@router.post("/analyze")
async def analyze_presentation(request: Request, user_id: str = Depends(get_current_user_id)):
    """Analyze a presentation transcription and store results in Supabase"""
    try:
        body = await request.json()
        transcription = body.get("transcription")
        report_id = body.get("reportId")
        topic = body.get("topic", "")
        
        # User ID is now directly provided by the dependency

        if not transcription or not report_id:
            raise HTTPException(status_code=400, detail="transcription and reportId are required")

        try:
            uuid.UUID(report_id, version=4)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid reportId format")

        analysis_results = analyzer.analyze_presentation(transcription, topic)

        user_report = UserReport(
            reportId=report_id,
            reportTopic=topic,
            scoreContext=analysis_results["overall_score"],
            subScoresContext=analysis_results["content_analysis"],
            weaknessTopicsContext=analysis_results["weakness_topics"],
            createdAt=datetime.datetime.now().isoformat(),
            userId=user_id
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

            print(f"\nUpdating context fields for report {report_id}: {update_data}")
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
            return {"message": "Analysis completed successfully and stored in Supabase"}
    except Exception as e:
        print(f"\nError during analysis: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/score")
async def get_overall_score(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the overall score of a specific analysis by Report ID"""
    response = storage_service.supabase.table("UserReport").select("scoreContext").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No analysis results found for this reportId")
    
    overall_score = response.data[0]["scoreContext"]
    print("\nReturning Overall Score:", overall_score)
    return {"overall_score": overall_score, "user_id": user_id}

@router.get("/sub_scores")
async def get_summery_score(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the content analysis scores of a specific analysis by Report ID"""
    response = storage_service.supabase.table("UserReport").select("subScoresContext").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

    sub_scores_context = response.data[0]["subScoresContext"]
    print("\nReturning Content Analysis:", sub_scores_context)
    return {"content_analysis": sub_scores_context}

@router.get("/weaknesses")
async def get_weaknesses(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the weakness analysis from a specific analysis by Report ID"""
    response = storage_service.supabase.table("UserReport").select("weaknessTopicsContext").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No analysis results found for this reportId")

    weakness_topics_context = response.data[0]["weaknessTopicsContext"]
    #print("\nReturning Weaknesses:", weakness_topics_context)
    return {"weakness_topics": weakness_topics_context}


@router.get("/reports")
async def list_reports(limit: int = Query(10, title="Limit"), offset: int = Query(0, title="Offset"), user_id: str = Depends(get_current_user_id)):
    """List all reports with pagination"""
    response = storage_service.supabase.table("UserReport").select("*").range(offset, offset + limit - 1).execute()

    if response.error:
        raise HTTPException(status_code=500, detail=response.error)

    return response.data


@router.delete("/report/delete/{reportId}")
async def delete_report(reportId: str, user_id: str = Depends(get_current_user_id)):
    """Remove a report"""
    response = storage_service.supabase.table("UserReport").delete().eq("reportId", reportId).execute()

    if response.error:
        raise HTTPException(status_code=500, detail=response.error)

    return {"message": f"Report with reportId {reportId} deleted successfully"}

    #confirmation needs to be added.

@router.get("/health")
async def health_check_context(user_id: str = Depends(get_current_user_id)):
    """Check if the API is running"""
    return {"status": "healthy"}