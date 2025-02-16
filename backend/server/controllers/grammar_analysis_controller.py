from fastapi import APIRouter, HTTPException, Request
from services.gemini_grammar_service import GeminiGrammarAnalyzer

router = APIRouter()
analyzer = GeminiGrammarAnalyzer()

# Store last analysis result
last_analysis = None


@router.post("/analyze")
async def analyze_grammar(request: Request):
    """Analyze text for grammatical correctness and store results"""
    try:
        body = await request.json()
        transcription = body.get("transcription")
        if not transcription:
            raise HTTPException(status_code=400, detail="Transcription text is required")
            
        global last_analysis
        last_analysis = analyzer.analyze_grammar(transcription)
        print("\nStored Grammar Analysis Result:")
        print(last_analysis)
        return {"message": "Grammar analysis completed successfully"}
    except Exception as e:
        print(f"\nError during grammar analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/score")
async def get_grammar_score():
    """Get the overall grammar score and confidence level"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")
    return {
        "grammar_score": last_analysis["grammar_score"],
        "confidence_level": last_analysis["confidence_level"]
    }


@router.get("/sub_scores")
async def get_detailed_analysis():
    """Get detailed analysis scores for grammar, structure, and word choice"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")
    return {"analysis": last_analysis["analysis"]}


@router.get("/weaknesses")
async def get_identified_issues():
    """Get list of identified grammar issues with suggestions"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No grammar analysis results found")
    return {"identified_issues": last_analysis["identified_issues"]}


@router.get("/health")
async def health_check():
    "Check if the API is running"
    return {"status": "healthy"}