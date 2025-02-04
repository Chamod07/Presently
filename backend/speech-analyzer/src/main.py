from fastapi import FastAPI, HTTPException
from services.audio_service import AudioService
from services.transcription_service import TranscriptionService
from services.analysis_service import AnalysisService

app = FastAPI()

audio_service = AudioService()
transcription_service = TranscriptionService()
analysis_service = AnalysisService()

@app.post("/analyze-speech")
async def analyze_speech(duration: int = 30):
    try:
        # Record audio
        audio_data = audio_service.record_audio(duration=duration)
        
        # Transcribe audio
        transcription = transcription_service.transcribe_audio(audio_data, sample_rate=44100)
        
        # Analyze speech
        analysis_results = analysis_service.analyze_speech(transcription, duration)
        
        return {
            "success": True,
            "transcription": transcription,
            "analysis": analysis_results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy"}