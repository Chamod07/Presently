import whisper
import os
import re

# Predefined list of filler words
FILLER_WORDS = {"uh", "um", "like", "you know", "hmm"}

def transcribe_audio(file_path):
    # Load the Whisper model
    model = whisper.load_model("small")

    # Check if the file exists
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.")
        return

    # Transcribe the audio file with word timestamps
    print("Transcribing audio...")
    result = model.transcribe(file_path, word_timestamps=True)

    # Extract transcription and segments
    transcription = result['text']
    segments = result.get('segments', [])
    print("Transcription completed.")

    return transcription, segments

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

def main():
    # Path to your MP3 file
    file_path = input("Enter the path to your MP3 file: ")

    # Transcribe the audio file
    transcription, segments = transcribe_audio(file_path)

    # Save the transcription to a text file
    if transcription:
        output_file = "transcription.txt"
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
    main()
