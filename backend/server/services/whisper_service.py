import warnings
import os
import torch
import whisper
import logging
import re

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

# Predefined list of filler words
FILLER_WORDS = {"uh", "um", "like", "you know", "hmm"}

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
        result = model.transcribe(audio_path)
        
        # Extract text and segments
        transcription = result["text"]
        segments = result["segments"]
        
        logger.info(f"Transcription complete{report_info}: {len(transcription)} characters")
        
        return transcription, segments
        
    except Exception as e:
        error_msg = f"Transcription error{' for report '+report_id if report_id else ''}: {str(e)}"
        logger.error(error_msg)
        raise

def analyze_speech_speed(segments):
    if not segments:
        return 0

    # Calculate total duration
    total_duration = segments[-1]['end'] - segments[0]['start']
    total_words = sum(len(segment['text'].split()) for segment in segments)

    # Words per minute (WPM)
    speech_speed = total_words / (total_duration / 60) if total_duration > 0 else 0
    return round(speech_speed, 2)

def analyze_filler_words(segments):
    filler_count = 0

    for segment in segments:
        text = segment['text'].lower()
        for filler in FILLER_WORDS:
            filler_count += text.count(filler)

    return filler_count

def analyze_stuttering(segments):
    stutters = 0

    for segment in segments:
        text = segment['text']
        stutter_matches = re.findall(r'\b(\w+)\s+\1\b', text)  # Detect repeated words
        stutters += len(stutter_matches)

    return stutters

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
        speech_speed = analyze_speech_speed(segments)
        filler_count = analyze_filler_words(segments)
        stutter_count = analyze_stuttering(segments)

        print(f"Speech Analysis:")
        print(f"  Speech Speed: {speech_speed} WPM")
        print(f"  Filler Words Count: {filler_count}")
        print(f"  Stutter Count: {stutter_count}")

if __name__ == "__main__":
    import sys
    
    # Accept a report ID as a command-line argument
    if len(sys.argv) > 1:
        report_id = sys.argv[1]
        main(report_id)
    else:
        main()
