class AudioService:
    def __init__(self):
        import sounddevice as sd
        import numpy as np
        self.sd = sd
        self.np = np

    def record_audio(self, duration=5, sample_rate=44100):
        print("Recording audio...")
        audio_data = self.sd.rec(int(duration * sample_rate), samplerate=sample_rate, channels=1, dtype='float32')
        self.sd.wait()  # Wait until recording is finished
        print("Recording finished.")
        return audio_data.flatten()  # Return audio data as a 1D array