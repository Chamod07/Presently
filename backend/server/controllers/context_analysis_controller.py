from fastapi import APIRouter, HTTPException, Request
from services.gemini_context_service import GeminiContextAnalyzer

router = APIRouter()
analyzer = GeminiContextAnalyzer()

# Store last analysis result
last_analysis = None

@router.post("/analyze")
async def analyze_presentation(request: Request):
    """Analyze a presentation transcription and store results"""
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
        
        global last_analysis
        last_analysis = analyzer.analyze_presentation(transcription)
        print("\nStored Analysis Result:")
        print(last_analysis)
        return {"message": "Analysis completed successfully"}
    except Exception as e:
        print(f"\nError during analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/score")
async def get_overall_score():
    """Get the overall score of the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Overall Score:", last_analysis["overall_score"])
    return {"overall_score": last_analysis["overall_score"]}

@router.get("/sub_scores")
async def get_summery_score():
    """Get the content analysis scores of the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Content Analysis:", last_analysis["content_analysis"])
    return {"content_analysis": last_analysis["content_analysis"]}

@router.get("/weaknesses")
async def get_weaknesses():
    """Get the weakness analysis from the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Weaknesses:", last_analysis["weakness_topics"])
    return {"weakness_topics": last_analysis["weakness_topics"]}

@router.get("/health")
async def health_check_context():
    """Check if the API is running"""
    return {"status": "healthy"}