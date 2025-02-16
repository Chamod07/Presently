from fastapi import FastAPI, HTTPException, Request
from backend.server.services.gemini_context_service import GeminiContextAnalyzer

app = FastAPI()
analyzer = GeminiContextAnalyzer()

# Store last analysis result
last_analysis = None


@app.post("/api/analyser/context/analyze")
async def analyze_presentation(request: Request):
    """Analyze a presentation transcription and store results"""
    try:
        body = await request.json()
        transcription = body.get("transcription")
        if not transcription:
            raise HTTPException(status_code=400, detail="Transcription text is required")
            
        global last_analysis
        last_analysis = analyzer.analyze_presentation(transcription)
        print("\nStored Analysis Result:")
        print(last_analysis)
        return {"message": "Analysis completed successfully"}
    except Exception as e:
        print(f"\nError during analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/analyser/context/score")
async def get_overall_score():
    """Get the overall score of the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Overall Score:", last_analysis["overall_score"])
    return {"overall_score": last_analysis["overall_score"]}


@app.get("/api/analyser/context/sub_scores")
async def get_summery_score():
    """Get the content analysis scores of the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Content Analysis:", last_analysis["content_analysis"])
    return {"content_analysis": last_analysis["content_analysis"]}


@app.get("/api/analyser/context/weaknesses")
async def get_weaknesses():
    """Get the weakness analysis from the latest analysis"""
    if not last_analysis:
        raise HTTPException(status_code=404, detail="No analysis results found")
    print("\nReturning Weaknesses:", last_analysis["weakness_topics"])
    return {"weakness_topics": last_analysis["weakness_topics"]}


@app.get("/api/analyser/context/health")
async def health_check_context():
    """Check if the API is running"""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)