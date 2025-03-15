import subprocess
import os

def convert_video_to_mp3(video_path, mp3_path):
    try:
        subprocess.run([
            "ffmpeg",
            "-i", video_path,
            mp3_path
        ], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error converting video to MP3: {e}")
        return False
    except FileNotFoundError:
        print("Error: ffmpeg not found. Please ensure ffmpeg is installed and in your system's PATH.")
        return False
