from fastapi import APIRouter, HTTPException, Depends, Query
from services.auth_service import get_current_user_id
from services import storage_service
from services.whisper_service import analyze_speech, transcribe_audio
import os
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Voice Analysis"])

@router.get("/score")
async def get_voice_score(
    report_id: str = Query(..., description="Report ID"), 
    user_id: str = Depends(get_current_user_id)):
    """Get the overall voice score for a report"""
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("scoreVoice") \
            .eq("reportId", report_id) \
            .execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Voice score not found")

        if "scoreVoice" not in response.data[0] or response.data[0]["scoreVoice"] is None:
            raise HTTPException(status_code=404, detail="Voice score not found")
        
        return {"scoreVoice": response.data[0]["scoreVoice"]}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.get("/weaknesses")
async def get_voice_weaknesses(
    report_id: str = Query(..., description="Report ID"),
    user_id: str = Depends(get_current_user_id)):
    """Get the weakness topics for voice analysis"""
    try:
        response = storage_service.supabase.table("UserReport") \
            .select("weaknessTopicsVoice") \
            .eq("reportId", report_id) \
            .execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="No voice weaknesses found")

        if "weaknessTopicsVoice" not in response.data[0] or response.data[0]["weaknessTopicsVoice"] is None:
            raise HTTPException(status_code=404, detail="No voice weaknesses found")

        return {"weaknessTopics": response.data[0]["weaknessTopicsVoice"]}
    except Exception as e:
        logger.error(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error")

@router.post("/analyze")
async def analyze_voice(report_id: str = Query(...)):
    """
    Analyze voice characteristics for a presentation.
    
    Parameters:
    - report_id: ID of the report to update
    
    Returns:
    - A status message indicating success
    """
    try:
        print("\n" + "-" * 60)
        print(f"VOICE ANALYSIS: Starting for report {report_id}")
        print("-" * 60)
        
        # Check if audio file exists
        audio_path = f"tmp/{report_id}/audio/audio.mp3"
        if not os.path.exists(audio_path):
            raise HTTPException(status_code=404, detail=f"Audio file not found at: {audio_path}")
            
        # Get transcription from file if exists, otherwise run transcription
        transcription_path = f"tmp/{report_id}/transcription/transcription.txt"
        if (os.path.exists(transcription_path)):
            print(f"[1/3] Using existing transcription from: {transcription_path}")
            with open(transcription_path, 'r', encoding='utf-8') as f:
                transcription = f.read()
        else:
            print(f"[1/3] Transcribing audio from: {audio_path}")
            transcription, _ = transcribe_audio(audio_path, report_id)
            # Save transcription
            os.makedirs(os.path.dirname(transcription_path), exist_ok=True)
            with open(transcription_path, 'w', encoding='utf-8') as f:
                f.write(transcription)
        
        # Analyze voice characteristics
        print(f"[2/3] Analyzing voice characteristics...")
        _, segments = transcribe_audio(audio_path, report_id)
        analysis_results = analyze_speech(segments, transcription)
        
        # Create report directory if it doesn't exist
        report_dir = f"tmp/{report_id}/reports"
        os.makedirs(report_dir, exist_ok=True)
        
        # Save voice analysis report
        print(f"[3/3] Saving voice analysis report...")
        report_path = f"{report_dir}/voice_analysis.txt"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("Voice Analysis Report\n")
            f.write("===================\n\n")
            f.write(f"Overall score: {analysis_results['score']}/10\n")
            f.write(f"Speech rate: {analysis_results['speech_rate']} words per minute\n")
            f.write(f"Filler words: {analysis_results.get('filler_words', 'N/A')}\n")
            f.write(f"Hesitations: {analysis_results.get('hesitations', 'N/A')}\n\n")
            
            f.write("Issues and Suggestions:\n")
            if analysis_results['issues']:
                for idx, issue in enumerate(analysis_results['issues'], 1):
                    f.write(f"{idx}. {issue['topic']}\n")
                    f.write(f"   Examples: {'; '.join(issue['examples'])}\n")
                    f.write(f"   Suggestions:\n")
                    for suggestion in issue['suggestions']:
                        f.write(f"   - {suggestion}\n")
                    f.write("\n")
            else:
                f.write("No significant issues detected. Great job!\n")
        
        # Update database with results
        update_data = {
            "scoreVoice": analysis_results['score'],
            "weaknessTopicsVoice": analysis_results['issues']
        }
        
        # Capture and handle the response instead of letting it print to console
        response = storage_service.supabase.table("UserReport").update(update_data).eq("reportId", report_id).execute()
        
        # Log the response data properly instead of printing "OK"
        if response.data:
            print(f"✓ Database updated successfully: {len(response.data)} records modified")
        else:
            print(f"! Database update returned no data")
        
        print(f"✓ VOICE ANALYSIS: Completed for report {report_id}")
        print("-" * 60 + "\n")
        
        return {
            "message": "Voice analysis completed successfully",
            "score": analysis_results['score'],
            "weaknesses_count": len(analysis_results['issues'])
        }
        
    except Exception as e:
        print(f"✗ VOICE ANALYSIS ERROR: {str(e)}")
        logger.error(f"Voice analysis error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Voice analysis failed: {str(e)}")
