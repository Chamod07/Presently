from fastapi import APIRouter, HTTPException, Request, Depends, Query
from services.gemini_grammar_service import GeminiGrammarAnalyzer
from models.user_report_model import UserReport
from services import storage_service
import datetime
import uuid
from fastapi import status
from services.auth_service import get_current_user_id
import logging

# Configure standard logging
logger = logging.getLogger(__name__)

router = APIRouter()
analyzer = GeminiGrammarAnalyzer()

@router.post("/analyze")
async def analyze_grammar(text: str, report_id: str):
    """
    Analyze grammar in a presentation transcription.
    
    Args:
        text: The text transcription of the presentation
        report_id: The ID of the report to update
        
    Returns:
        A message indicating successful analysis
    """
    try:
        # Better step logging with visual separators
        print("\n" + "-" * 60)
        print(f"GRAMMAR ANALYSIS: Starting for report {report_id}")
        print("-" * 60)
        
        logger.info(f"Analyzing grammar for report ID: {report_id}")
        
        # Check if text is valid
        if not text or len(text.strip()) < 10:
            print("✗ Error: Text is too short or empty")
            raise HTTPException(status_code=400, detail="Text is too short or empty")
        
        print(f"[1/3] Processing {len(text)} characters of text...")
            
        # Analyze grammar with the service
        print(f"[2/3] Running grammar analysis with AI...")
        grammar_results = analyzer.analyze_grammar(text)
        
        # Format the results for storage
        score = grammar_results.get("score", 0)
        weaknesses = grammar_results.get("weaknesses", [])
        
        print(f"[2/3] Analysis results: Score {score}/10 with {len(weaknesses)} identified issues")
        
        # Update the database with results
        print(f"[3/3] Saving results to database...")
        update_data = {
            "scoreGrammar": score,
            "weaknessTopicsGrammar": weaknesses
        }
        
        storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
        
        print(f"✓ GRAMMAR ANALYSIS: Completed for report {report_id}")
        print("-" * 60 + "\n")
        
        return {
            "message": "Grammar analysis completed successfully",
            "score": score,
            "weaknesses_count": len(weaknesses)
        }
        
    except Exception as e:
        print(f"✗ GRAMMAR ANALYSIS ERROR: {str(e)}")
        logger.error(f"Grammar analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Grammar analysis failed: {str(e)}")


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
