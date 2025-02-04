from ..utils.constants import FILLER_WORDS, SPEECH_RATE, SCORING_WEIGHTS
import numpy as np

class AnalysisService:
    def analyze_speech(self, transcription, audio_duration):
        """
        Analyze the speech and return scores and feedback
        """
        # Calculate metrics
        words = transcription.split()
        total_words = len(words)
        
        # Calculate speech rate (words per minute)
        speech_rate = (total_words / audio_duration) * 60
        
        # Count filler words
        filler_word_count = sum(1 for word in words if word.lower() in FILLER_WORDS)
        filler_word_ratio = filler_word_count / total_words if total_words > 0 else 0
        
        # Calculate scores
        speech_rate_score = self._calculate_speech_rate_score(speech_rate)
        filler_words_score = max(0, 1 - (filler_word_ratio * 2))  # Penalize for filler words
        
        # Calculate final score
        final_score = (
            speech_rate_score * SCORING_WEIGHTS["SPEECH_RATE"] +
            filler_words_score * SCORING_WEIGHTS["FILLER_WORDS"]
        )
        
        return {
            "score": round(final_score * 100, 2),
            "metrics": {
                "speech_rate": round(speech_rate, 2),
                "filler_words_count": filler_word_count,
                "total_words": total_words
            },
            "feedback": self._generate_feedback(speech_rate, filler_word_count, total_words)
        }
    
    def _calculate_speech_rate_score(self, rate):
        if rate < SPEECH_RATE["TOO_SLOW"]:
            return max(0.5, rate / SPEECH_RATE["OPTIMAL_MIN"])
        elif rate > SPEECH_RATE["TOO_FAST"]:
            return max(0.5, 1 - ((rate - SPEECH_RATE["OPTIMAL_MAX"]) / SPEECH_RATE["OPTIMAL_MAX"]))
        else:
            return 1.0
    
    def _generate_feedback(self, speech_rate, filler_words, total_words):
        feedback = []
        
        # Speech rate feedback
        if speech_rate < SPEECH_RATE["TOO_SLOW"]:
            feedback.append("Try to speak a bit faster to maintain audience engagement.")
        elif speech_rate > SPEECH_RATE["TOO_FAST"]:
            feedback.append("Try to slow down a bit for better clarity.")
        else:
            feedback.append("Your speaking pace is good!")
            
        # Filler words feedback
        if filler_words > 0:
            ratio = filler_words / total_words
            if ratio > 0.1:
                feedback.append(f"Try to reduce filler words (used {filler_words} times).")
            elif ratio > 0.05:
                feedback.append("Watch out for occasional filler words.")
                
        return feedback
