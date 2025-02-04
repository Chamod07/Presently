import unittest
from src.services.audio_service import AudioService

class TestAudioService(unittest.TestCase):

    def setUp(self):
        self.audio_service = AudioService()

    def test_record_audio(self):
        audio_data = self.audio_service.record_audio(duration=5)
        self.assertIsNotNone(audio_data)
        self.assertGreater(len(audio_data), 0)

if __name__ == '__main__':
    unittest.main()