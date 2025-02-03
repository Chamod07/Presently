import whisper
import os
import re
from collections import Counter

# Enhanced list of filler words
FILLER_WORDS = {
    "uh", "um", "like", "you know", "hmm", "er", "ah", "uhh", "well", "so", 
    "basically", "literally", "actually", "sort of", "kind of"
}

def transcribe_audio(file_path):
    # Load the Whisper model - using 'medium' for better accuracy
    model = whisper.load_model("medium")

    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.")
        return None, None

    print("Transcribing audio...")
    # Using more parameters for better accuracy
    result = model.transcribe(
        file_path,
        word_timestamps=True,
        language="en",  # Force English for better accuracy
        fp16=False  # Better precision with fp32
    )

    return result['text'], result.get('segments', [])

def analyze_speech_speed(segments):
    if not segments:
        return 0, 0

    total_duration = segments[-1]['end'] - segments[0]['start']
    word_count = sum(len(segment['text'].split()) for segment in segments)
    
    wpm = word_count / (total_duration / 60) if total_duration > 0 else 0
    wps = word_count / total_duration if total_duration > 0 else 0
    
    return round(wpm, 2), round(wps, 2)

def analyze_clarity(segments):
    if not segments:
        return 0

    total_score = 0
    for segment in segments:
        confidence = segment.get('confidence', 0)
        segment_length = segment['end'] - segment['start']
        if segment_length < 0.1 or segment_length > 10:
            confidence *= 0.8

        total_score += confidence

    avg_clarity = (total_score / len(segments)) * 100 if segments else 0
    return round(avg_clarity, 2)

def analyze_filler_words(segments):
    filler_count = Counter()

    for segment in segments:
        text = segment['text'].lower()
        for filler in FILLER_WORDS:
            count = len(re.findall(r'\b' + re.escape(filler) + r'\b', text))
            filler_count[filler] += count

    return dict(filler_count)

def analyze_stuttering(segments):
    stutters = []
    stutter_timestamps = []

    for segment in segments:
        text = segment['text'].lower()
        words = text.split()
        
        # Check for immediate word repetitions
        for i in range(len(words) - 1):
            if words[i] == words[i + 1]:
                stutters.append(words[i])
                stutter_timestamps.append({
                    'word': words[i],
                    'time': segment['start'] + (segment['end'] - segment['start']) * (i / len(words))
                })
        
        # Check for partial word repetitions (e.g., "st-st-stutter")
        partial_stutters = re.findall(r'(\w+)-\1+\b|\b(\w+)(?:\s+\2)+\b', text)
        for stutter in partial_stutters:
            stutter = next(s for s in stutter if s)  # Get non-empty match
            stutters.append(stutter)

    return len(stutters), stutters, stutter_timestamps

def main():
    file_path = input("Enter the path to your MP3 file: ")
    transcription, segments = transcribe_audio(file_path)

    if transcription:
        with open("transcription.txt", "w", encoding="utf-8") as f:
            f.write(transcription)
        print("Transcription saved to 'transcription.txt'")

        if segments:
            wpm, wps = analyze_speech_speed(segments)
            clarity_score = analyze_clarity(segments)
            filler_words = analyze_filler_words(segments)
            stutter_count, stuttered_words, stutter_times = analyze_stuttering(segments)

            print("\nSpeech Analysis:")
            print(f"  Speech Speed: {wpm} WPM ({wps} words/sec)")
            print(f"  Clarity Score: {clarity_score}%")
            print(f"  Filler Words Detail: {dict(filler_words)}")
            print(f"  Total Filler Words: {sum(filler_words.values())}")
            print(f"  Stutter Count: {stutter_count}")
            if stuttered_words:
                print(f"  Stuttered Words: {', '.join(stuttered_words)}")
                print("\nStutter Timestamps:")
                for st in stutter_times:
                    print(f"    '{st['word']}' at {round(st['time'], 2)} seconds")

if __name__ == "__main__":
    main()
