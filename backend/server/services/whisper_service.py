import warnings
import os
import torch
import whisper
import logging
import re
import numpy as np
from collections import Counter

# Configure logging
logger = logging.getLogger(__name__)

# Aggressively suppress all warnings
warnings.filterwarnings("ignore")

# Suppress specific PyTorch warnings
warnings.filterwarnings(
    "ignore", 
    message="You are using `torch.load` with `weights_only=False`", 
    category=FutureWarning
)
warnings.filterwarnings(
    "ignore", 
    message="FP16 is not supported on CPU", 
    category=UserWarning
)
warnings.filterwarnings(
    "ignore", 
    message="torch.nn.utils.weight_norm is deprecated", 
    category=UserWarning
)

# Silence other TensorFlow/CUDA/PyTorch warnings
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['CUDA_DEVICE_ORDER'] = 'PCI_BUS_ID'
os.environ['CUDA_VISIBLE_DEVICES'] = ''  # Hide CUDA devices
torch.set_warn_always(False)

# Completely disable PyTorch warnings at C++ level if possible
try:
    torch._C._set_print_stack_traces_on_fatal_signal(False)
except:
    pass

# Predefined lists for speech analysis
FILLER_WORDS = {
    "uh", "um", "er", "ah", "like", "you know", "hmm", "so", "basically", 
    "actually", "literally", "sort of", "kind of", "i mean", "right", "okay"
}

HESITATION_PATTERNS = [
    r'\b(\w+)\s+\1\b',                  # Repeated words
    r'\b(um|uh|er|ah)+\b',              # Filler sounds
    r'(?<!\w)(\.\.\.|…)(?!\w)',         # Ellipses
    r'\b(so|well)\b(?=\s+\w+)',         # Starting sentences with "so" or "well"
]

def transcribe_audio(audio_path, report_id=None):
    """
    Transcribe audio to text using Whisper ASR model.
    
    Args:
        audio_path: Path to the audio file to transcribe
        report_id: Optional ID of the report being processed (for logging)
        
    Returns:
        A tuple of (transcription_text, segments)
    """
    try:
        report_info = f" for report {report_id}" if report_id else ""
        logger.info(f"Transcribing audio{report_info}...")
        
        # Check if audio file exists
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found at {audio_path}")
            
        # Load model (this uses torch.load under the hood)
        model = whisper.load_model("base")
        
        # Transcribe audio
        result = model.transcribe(audio_path) # This also returns segmented data with timestamps
        
        # Extract text and segments
        transcription = result["text"]
        segments = result["segments"]
        
        logger.info(f"Transcription complete{report_info}: {len(transcription)} characters")
        
        return transcription, segments
        
    except Exception as e:
        error_msg = f"Transcription error{' for report '+report_id if report_id else ''}: {str(e)}"
        logger.error(error_msg)
        raise

def analyze_speech(segments, transcription):
    """
    Perform comprehensive analysis of speech patterns and characteristics.
    
    Args:
        segments: Segment data from Whisper transcription
        transcription: Full transcription text
        
    Returns:
        Dictionary with speech analysis results
    """
    if not segments or not transcription:
        return {
            "score": 5,
            "speech_rate": 0,
            "issues": []
        }
    
    # Calculate basic speech metrics
    speech_rate = analyze_speech_speed(segments)
    filler_count, filler_stats = analyze_filler_words(transcription)
    hesitation_count = analyze_hesitations(transcription)
    clarity_score = analyze_speech_clarity(transcription, segments)
    variety_score = analyze_speech_variety(transcription, segments)
    
    # Calculate sentence length and variation
    sentence_stats = analyze_sentence_structure(transcription)
    
    # Calculate pauses and rhythm
    pause_stats = analyze_pauses(segments)
    
    # Generate feedback
    issues = []
    
    # Issue: Speech rate
    if speech_rate > 180:
        issues.append({
            "topic": "Speaking Too Fast",
            "examples": [f"Your speaking rate is {speech_rate} words per minute, which is faster than the ideal range."],
            "suggestions": [
                "Practice speaking more slowly during rehearsals", 
                "Add deliberate pauses between key points", 
                "Mark your notes with reminders to slow down"
            ]
        })
    elif speech_rate < 120:
        issues.append({
            "topic": "Speaking Too Slowly",
            "examples": [f"Your speaking rate is {speech_rate} words per minute, which is slower than the ideal range."],
            "suggestions": [
                "Practice your presentation to become more comfortable with the material", 
                "Record yourself and listen for unnecessarily long pauses", 
                "Focus on maintaining a more engaging pace"
            ]
        })
        
    # Issue: Filler words
    if filler_count > 5:
        filler_rate = filler_count / (len(transcription.split()) / 100)  # Fillers per 100 words
        if filler_rate > 3:
            examples = [f"You used filler words {filler_count} times in your presentation."]
            
            # Add top 3 filler words as examples
            if filler_stats:
                top_fillers = sorted(filler_stats.items(), key=lambda x: x[1], reverse=True)[:3]
                for filler, count in top_fillers:
                    examples.append(f"'{filler}' was used {count} times")
                    
            issues.append({
                "topic": "Excessive Filler Words",
                "examples": examples,
                "suggestions": [
                    "Practice pausing silently instead of using filler words", 
                    "Record yourself to become more aware of your filler word habits", 
                    "Have a colleague signal you when you use filler words during practice"
                ]
            })
    
    # Issue: Hesitations
    if hesitation_count > 5:
        issues.append({
            "topic": "Speech Hesitations",
            "examples": [f"You showed {hesitation_count} instances of speech hesitation."],
            "suggestions": [
                "Practice your presentation more thoroughly to build confidence", 
                "Simplify complex sections that may cause hesitation", 
                "Take a brief pause instead of hesitating or repeating words"
            ]
        })
    
    # Issue: Speech clarity
    if clarity_score < 7:
        issues.append({
            "topic": "Speech Clarity",
            "examples": ["Your speech lacks clarity in several sections."],
            "suggestions": [
                "Practice enunciating challenging words and phrases", 
                "Slow down during complex explanations", 
                "Consider simplifying technical terminology when possible"
            ]
        })
    
    # Issue: Speech variety/monotony
    if variety_score < 6:
        issues.append({
            "topic": "Monotonous Delivery",
            "examples": ["Your speech shows limited vocal variety and expression."],
            "suggestions": [
                "Practice emphasizing key words and phrases", 
                "Vary your pace - slow down for important points, speed up for examples", 
                "Add deliberate pauses before and after important points"
            ]
        })
    
    # Issue: Sentence structure
    if sentence_stats["avg_length"] > 25:
        issues.append({
            "topic": "Overly Complex Sentences",
            "examples": [f"Your sentences average {sentence_stats['avg_length']:.1f} words in length, which can be difficult to follow."],
            "suggestions": [
                "Break long sentences into shorter, clearer statements", 
                "Aim for sentences of 15-20 words maximum", 
                "Use bullet points for complex information"
            ]
        })
    elif sentence_stats["variety"] < 0.4:
        issues.append({
            "topic": "Repetitive Sentence Structure",
            "examples": ["Your presentation uses similar sentence patterns throughout."],
            "suggestions": [
                "Mix short statements with longer explanations", 
                "Use questions to engage the audience", 
                "Vary how you begin sentences"
            ]
        })
    
    # Issue: Pauses
    if pause_stats["count"] < 3 and len(segments) > 10:
        issues.append({
            "topic": "Insufficient Pausing",
            "examples": ["You rarely pause during your presentation, making it difficult for listeners to process information."],
            "suggestions": [
                "Add deliberate pauses after key points", 
                "Mark pause points in your notes or slides", 
                "Practice the 'pause and breathe' technique"
            ]
        })
    elif pause_stats["consistency"] < 0.5:
        issues.append({
            "topic": "Inconsistent Rhythm",
            "examples": ["Your pausing pattern is inconsistent, creating an uneven presentation flow."],
            "suggestions": [
                "Structure your pauses more deliberately", 
                "Practice with a metronome to develop rhythm awareness", 
                "Use slide transitions as natural pause points"
            ]
        })
    
    # Calculate overall score
    if len(issues) == 0:
        score = 9  # Excellent
    else:
        # Base score of 9, deduct points based on the number and severity of issues
        score = max(3, 9 - len(issues) * 0.8)
    
    return {
        "score": round(score),
        "speech_rate": speech_rate,
        "filler_words": filler_count,
        "hesitations": hesitation_count,
        "clarity_score": clarity_score,
        "variety_score": variety_score,
        "sentence_length": sentence_stats["avg_length"],
        "issues": issues
    }

def analyze_speech_speed(segments):
    """Calculate speech rate in words per minute"""
    if not segments:
        return 0

    # Calculate total duration
    total_duration = segments[-1]['end'] - segments[0]['start']
    total_words = sum(len(segment['text'].split()) for segment in segments)

    # Words per minute (WPM)
    speech_speed = total_words / (total_duration / 60) if total_duration > 0 else 0
    return round(speech_speed, 1)

def analyze_filler_words(transcription):
    """Analyze filler word usage and return count and statistics"""
    text_lower = transcription.lower()
    words = text_lower.split()
    
    filler_count = 0
    filler_stats = {}
    
    # Count individual filler words
    for filler in FILLER_WORDS:
        if ' ' in filler:  # Multi-word filler
            count = text_lower.count(filler)
        else:  # Single word filler
            count = sum(1 for word in words if word == filler)
            
        if count > 0:
            filler_stats[filler] = count
            filler_count += count
    
    return filler_count, filler_stats

def analyze_hesitations(transcription):
    """Analyze speech hesitations and stuttering patterns"""
    hesitation_count = 0
    
    for pattern in HESITATION_PATTERNS:
        matches = re.findall(pattern, transcription, re.IGNORECASE)
        hesitation_count += len(matches)
    
    return hesitation_count

def analyze_speech_clarity(transcription, segments):
    """Analyze speech clarity on a scale of 1-10"""
    # This is a simplified approximation that could be enhanced with actual audio analysis
    
    # Factors affecting clarity:
    # 1. Average segment length (longer = more clear)
    # 2. Word complexity (more syllables = potentially less clear)
    # 3. Hesitations (more = less clear)
    
    if not segments or not transcription:
        return 5  # Default middle score
    
    # Average segment length
    avg_seg_length = sum(len(segment['text'].split()) for segment in segments) / len(segments)
    
    # Clarity increases with reasonable segment length (not too short, not too long)
    clarity_score = 7.0  # Start with default
    
    # Adjust for segment length (ideal is 8-15 words)
    if avg_seg_length < 3:
        clarity_score -= 3  # Very choppy speech
    elif avg_seg_length < 5:
        clarity_score -= 1.5  # Somewhat choppy
    elif avg_seg_length > 20:
        clarity_score -= 2  # Too long, likely unclear
    elif avg_seg_length > 15:
        clarity_score -= 0.5  # Slightly too long
        
    # Adjust for hesitations
    hesitation_count = analyze_hesitations(transcription)
    hesitation_ratio = hesitation_count / max(1, len(transcription.split()) / 100)
    
    if hesitation_ratio > 5:
        clarity_score -= 3
    elif hesitation_ratio > 3:
        clarity_score -= 2
    elif hesitation_ratio > 1:
        clarity_score -= 1
        
    # Ensure score is within range
    return max(1, min(10, round(clarity_score)))

def analyze_speech_variety(transcription, segments):
    """Analyze speech variety/expression on a scale of 1-10"""
    # This is an approximation that could be enhanced with actual audio analysis of pitch and tone
    
    if not segments or not transcription:
        return 5  # Default middle score
    
    # Factors indicating variety:
    # 1. Variation in segment duration
    # 2. Variation in segment length (words)
    # 3. Use of punctuation like ! and ? in transcription
    
    # Calculate variation in segment duration
    durations = [segment['end'] - segment['start'] for segment in segments]
    if durations:
        mean_duration = sum(durations) / len(durations)
        variation_coef = np.std(durations) / mean_duration if mean_duration > 0 else 0
    else:
        variation_coef = 0
        
    # Calculate variation in segment length (words)
    word_counts = [len(segment['text'].split()) for segment in segments]
    if word_counts:
        mean_words = sum(word_counts) / len(word_counts)
        word_variation = np.std(word_counts) / mean_words if mean_words > 0 else 0
    else:
        word_variation = 0
        
    # Check for expressive punctuation
    exclamations = transcription.count('!')
    questions = transcription.count('?')
    word_count = len(transcription.split())
    punctuation_ratio = (exclamations + questions) / max(1, word_count / 100)
    
    # Calculate variety score
    variety_score = 5.0  # Start with middle score
    
    # Adjust for duration variation (more variation = more expressive)
    if variation_coef > 0.5:
        variety_score += 2
    elif variation_coef > 0.3:
        variety_score += 1
    elif variation_coef < 0.1:
        variety_score -= 1.5  # Very monotonous timing
        
    # Adjust for word count variation
    if word_variation > 0.7:
        variety_score += 1.5
    elif word_variation > 0.4:
        variety_score += 0.5
    elif word_variation < 0.2:
        variety_score -= 1  # Very uniform sentence length
        
    # Adjust for expressive punctuation
    if punctuation_ratio > 5:
        variety_score += 2
    elif punctuation_ratio > 2:
        variety_score += 1
        
    # Ensure score is within range
    return max(1, min(10, round(variety_score)))

def analyze_sentence_structure(transcription):
    """Analyze sentence structure and variety"""
    if not transcription:
        return {"avg_length": 0, "variety": 0}
    
    # Split into sentences
    sentences = re.split(r'[.!?]+', transcription)
    sentences = [s.strip() for s in sentences if s.strip()]
    
    if not sentences:
        return {"avg_length": 0, "variety": 0}
    
    # Calculate average sentence length
    lengths = [len(s.split()) for s in sentences]
    avg_length = sum(lengths) / len(lengths)
    
    # Calculate sentence variety
    # Look at first words to check for variety in sentence starts
    first_words = [s.split()[0].lower() if s.split() else "" for s in sentences]
    first_word_counts = Counter(first_words)
    
    # Calculate the proportion of unique sentence starters
    unique_starters = len(first_word_counts)
    variety = unique_starters / len(sentences)
    
    return {
        "avg_length": avg_length,
        "variety": variety
    }

def analyze_pauses(segments):
    """Analyze pausing patterns in speech"""
    if not segments or len(segments) < 2:
        return {"count": 0, "avg_duration": 0, "consistency": 0}
    
    pauses = []
    for i in range(1, len(segments)):
        # Calculate gap between segments
        gap = segments[i]['start'] - segments[i-1]['end']
        if gap > 0.5:  # Only count gaps longer than 0.5 seconds as deliberate pauses
            pauses.append(gap)
    
    if not pauses:
        return {"count": 0, "avg_duration": 0, "consistency": 0}
    
    avg_duration = sum(pauses) / len(pauses)
    
    # Consistency is measured as inverse of coefficient of variation
    # Higher values mean more consistent pause lengths
    std_dev = np.std(pauses)
    consistency = 1 - (std_dev / avg_duration) if avg_duration > 0 else 0
    consistency = max(0, min(1, consistency))  # Bound between 0 and 1
    
    return {
        "count": len(pauses),
        "avg_duration": avg_duration,
        "consistency": consistency
    }

def main(report_id=None):
    """
    Test function for local whisper transcription.
    
    Args:
        report_id: Optional report ID to use for file paths. If not provided,
                  a "test_report" ID will be used.
    """
    # Use provided report ID or default to test_report
    report_id = report_id or "test_report"
    
    # Use standardized tmp directory structure
    audio_dir = f"tmp/{report_id}/audio"
    transcription_dir = f"tmp/{report_id}/transcription"
    
    # Create directories if they don't exist
    os.makedirs(audio_dir, exist_ok=True)
    os.makedirs(transcription_dir, exist_ok=True)
    
    # Standardized file paths
    file_path = f"{audio_dir}/audio.mp3"
    
    # Check if test file exists, otherwise notify user
    if not os.path.exists(file_path):
        print(f"Audio file not found at {file_path}.")
        print(f"Please place an audio file at this location or specify another report ID.")
        return
    
    print(f"Processing audio for report ID: {report_id}")
    print(f"Audio path: {file_path}")

    # Transcribe the audio file
    transcription, segments = transcribe_audio(file_path, report_id)

    # Save the transcription to a text file
    if transcription:
        output_file = f"{transcription_dir}/transcription.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(transcription)
        print(f"Transcription saved to '{output_file}'.")

    # Analyze speech features
    if segments:
        speech_analysis = analyze_speech(segments, transcription)
        
        print(f"\nSpeech Analysis Results:")
        print(f"  Overall Score: {speech_analysis['score']}/10")
        print(f"  Speech Rate: {speech_analysis['speech_rate']} WPM")
        print(f"  Filler Words Count: {speech_analysis['filler_words']}")
        print(f"  Hesitation Count: {speech_analysis['hesitations']}")
        
        print(f"\nIdentified Issues:")
        for issue in speech_analysis["issues"]:
            print(f"  - {issue['topic']}")
            for suggestion in issue['suggestions']:
                print(f"    * {suggestion}")

if __name__ == "__main__":
    import sys
    
    # Accept a report ID as a command-line argument
    if len(sys.argv) > 1:
        report_id = sys.argv[1]
        main(report_id)
    else:
        main()
