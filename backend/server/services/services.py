import whisper
import os

def transcribe_audio(file_path):
    # Load the Whisper model (small model is used for faster processing, you can adjust the model size as needed)
    model = whisper.load_model("small")

    # Check if the file exists
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.")
        return

    # Transcribe the audio file
    print("Transcribing audio...")
    result = model.transcribe(file_path)

    # Extract the transcription
    transcription = result['text']

    print("Transcription completed.")
    return transcription

def main():
    # Path to your MP3 file
    file_path = input("Enter the path to your MP3 file: ")

    # Transcribe the audio file
    transcription = transcribe_audio(file_path)

    # Save the transcription to a text file
    if transcription:
        output_file = "transcription.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(transcription)
        print(f"Transcription saved to '{output_file}'.")

if __name__ == "__main__":
    main()
