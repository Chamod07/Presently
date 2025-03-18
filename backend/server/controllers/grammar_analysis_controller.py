from fastapi import APIRouter, HTTPException, Request, Depends
from services.gemini_grammar_service import GeminiGrammarAnalyzer
from models.user_report_model import UserReport
from services import storage_service
from fastapi import Query
import datetime
import uuid
from fastapi import status
from services.auth_service import get_current_user_id
import logging

logger = logging.getLogger(__name__)


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
            logger.error(f"Invalid reportId format: {report_id}")
            raise HTTPException(status_code=400, detail="Invalid reportId format")

        try:
            analysis_results = analyzer.analyze_grammar(transcription)
        except Exception as e:
            logger.error(f"Error during grammar analysis: {str(e)}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
            

        user_report = UserReport(
            reportId=report_id,
            reportTopic=topic,
            createdAt=datetime.datetime.now().isoformat(),
            scoreGrammar=float(analysis_results["grammar_score"]),
            subScoresGrammar={
                "grammaticalAccuracy": analysis_results["analysis"]["grammatical_accuracy"],
                "sentenceStructure": analysis_results["analysis"]["sentence_structure"],
                "wordChoice": analysis_results["analysis"]["word_choice"]
            },
            weaknessTopicsGrammar=[{
                "topic": wt["topic"],
                "examples": wt["examples"],
                "suggestions": wt["suggestions"]
            } for wt in analysis_results["weakness_topics"]]
        )

        data = user_report.dict()

        # Check if a report with the given reportId already exists
        existing_report = storage_service.supabase.table("UserReport").select("*").eq("reportId", report_id).execute()

        if existing_report.data:
            # Update only grammar-related fields
            update_data = {
                "scoreGrammar": float(analysis_results["grammar_score"]),
                "subScoresGrammar": {
                    "grammaticalAccuracy": analysis_results["analysis"]["grammatical_accuracy"],
                    "sentenceStructure": analysis_results["analysis"]["sentence_structure"],
                    "wordChoice": analysis_results["analysis"]["word_choice"]
                },
                "weaknessTopicsGrammar": [{
                    "topic": wt["topic"],
                    "examples": wt["examples"],
                    "suggestions": wt["suggestions"]
                } for wt in analysis_results["weakness_topics"]],
                #"updatedAt": datetime.datetime.now().isoformat()
            }
            
            print(f"\nUpdating grammar fields for report {report_id}")
            response = storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
            print(f"Update result: {response.data}")
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
async def get_grammar_score(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get the overall grammar score"""
    response = storage_service.supabase.table("UserReport").select("scoreGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    grammar_score = response.data[0]["scoreGrammar"]
    return {
        "grammar_score": grammar_score,
    }


@router.get("/sub_scores")
async def get_detailed_analysis(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get detailed analysis scores for grammar, structure, and word choice"""
    response = storage_service.supabase.table("UserReport").select("subScoresGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    analysis = response.data[0]["subScoresGrammar"]
    return {"analysis": analysis}


@router.get("/weaknesses")
async def get_identified_issues(report_id: str = Query(..., title="Report ID"), user_id: str = Depends(get_current_user_id)):
    """Get list of identified grammar topics with examples and suggestions"""
    response = storage_service.supabase.table("UserReport").select("weaknessTopicsGrammar").eq("reportId", report_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")

    weakness_topics = response.data[0]["weaknessTopicsGrammar"]
    return {"weakness_topics": weakness_topics}


@router.get("/health")
async def health_check(user_id: str = Depends(get_current_user_id)):
    "Check if the API is running"
    return {"status": "healthy"}
