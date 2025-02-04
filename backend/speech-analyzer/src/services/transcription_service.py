import whisper

class TranscriptionService:
    def __init__(self):
        self.model = whisper.load_model("medium")

    def transcribe_audio(self, audio_data, sample_rate):
        """
        Transcribe audio data to text using Whisper
        """
        try:
            result = self.model.transcribe(audio_data)
            return result["text"]
        except Exception as e:
            raise Exception(f"Transcription failed: {str(e)}")
