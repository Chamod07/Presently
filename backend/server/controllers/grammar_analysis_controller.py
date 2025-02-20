from fastapi import APIRouter, HTTPException, Request
from services.gemini_grammar_service import GeminiGrammarAnalyzer
from models.user_report_model import UserReport
from services import storage_service
from fastapi import Query
import datetime
import uuid
from fastapi import status

router = APIRouter()
analyzer = GeminiGrammarAnalyzer()

@router.post("/analyze")
async def analyze_grammar(request: Request):
    """Analyze text for grammatical correctness and store results"""
    try:
        body = await request.json()
        transcription = body.get("transcription")
        report_id = body.get("reportId")
        topic = body.get("topic", "")

        if not transcription or not report_id:
            raise HTTPException(status_code=400, detail="Transcription text and reportId are required")

        try:
            uuid.UUID(report_id, version=4)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid reportId format")

        analysis_results = analyzer.analyze_grammar(transcription)

        user_report = UserReport(
            reportId=report_id,
            reportTopic=topic,
            createdAt=datetime.datetime.now().isoformat(),
            userId="130761fb-86ba-4a34-8bc3-0414c9ef91e6",  # Use the provided userId
            scoreGrammar=analysis_results["grammar_score"],
            subScoresGrammar=analysis_results["analysis"],
            weaknessTopicsGrammar=analysis_results["identified_issues"]
        )

        data = user_report.dict()

        # Check if a report with the given reportId already exists
        existing_report = storage_service.supabase.table("UserReport").select("*").eq("reportId", report_id).execute()

        if existing_report.data:
            # Update the existing report
            response = storage_service.supabase.table("UserReport").update(data).eq("reportId", report_id).execute()
            if response.data and "error" in response.data:
                raise HTTPException(status_code=500, detail=response.data["error"])
            return {"message": f"Grammar analysis completed successfully and updated report with reportId {report_id}"}
        else:
            # Insert a new report
            response = storage_service.supabase.table("UserReport").insert(data).execute()
            if response.data and "error" in response.data:
                raise HTTPException(status_code=500, detail=response.data["error"])
            return {"message": "Grammar analysis completed successfully and stored in Supabase"}

    except Exception as e:
        print(f"\nError during grammar analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/score")
async def get_grammar_score(report_id: str = Query(..., title="Report ID")):
    """Get the overall grammar score"""
    response = storage_service.supabase.table("UserReport").select("scoreGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    grammar_score = response.data[0]["scoreGrammar"]
    return {
        "grammar_score": grammar_score,
    }



@router.get("/sub_scores")
async def get_detailed_analysis(report_id: str = Query(..., title="Report ID")):
    """Get detailed analysis scores for grammar, structure, and word choice"""
    response = storage_service.supabase.table("UserReport").select("subScoresGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    analysis = response.data[0]["subScoresGrammar"]
    return {"analysis": analysis}


@router.get("/weaknesses")
async def get_identified_issues(report_id: str = Query(..., title="Report ID")):
    """Get list of identified grammar issues with suggestions"""
    response = storage_service.supabase.table("UserReport").select("weaknessTopicsGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    identified_issues = response.data[0]["weaknessTopicsGrammar"]
    return {"identified_issues": identified_issues}

@router.get("/health")
async def health_check():
    "Check if the API is running"
    return {"status": "healthy"}