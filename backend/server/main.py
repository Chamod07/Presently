# uvicorn main:app --reload (to start the server)

from dotenv import load_dotenv
import os
import warnings
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

# Basic warning suppression - keeping this minimal
warnings.filterwarnings('ignore')

# Keep only essential environment variables
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

# Import logging utilities - but not the aggressive suppressors
from services.logging_utils import init_mediapipe

# Import TensorFlow after setting env vars
import tensorflow as tf
tf.get_logger().setLevel('ERROR')

from controllers.task_assign_controller import router as task_assign_router
from controllers.context_analysis_controller import router as context_router
from controllers.grammar_analysis_controller import router as grammar_router
from controllers.body_language_analysis_controller import router as body_language_router
from controllers.voice_analysis_controller import router as voice_router
from controllers.video_process_controller import router as video_process_router
from controllers.audio_process_controller import router as audio_process_router
from controllers.main_process_controller import router as main_controller
from controllers.report_controller import router as report_router
from routers import auth, upload

# Configure logging with standard settings
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

load_dotenv()  # Load environment variables from .env

app = FastAPI(title="Presently Backend")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development only - in production specify domains
    allow_credentials=True, 
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
    expose_headers=["*"],  # This is important for proper CORS operation
)

# Register all API routes individually
app.include_router(task_assign_router, prefix="/api/task-assign", tags=["task assign"])
app.include_router(auth.router, prefix="/api/auth")
app.include_router(upload.router, tags=["upload"])
app.include_router(grammar_router, prefix="/api/analyser/grammar", tags=["grammar"])
app.include_router(context_router, prefix="/api/analyser/context", tags=["context"])
app.include_router(body_language_router, prefix="/api/analyser/body-language", tags=["Body Language Analysis"])
app.include_router(voice_router, prefix="/api/analyser/voice", tags=["Voice Analysis"])
app.include_router(video_process_router, prefix="/api/process/video", tags=["Video Processing"])
app.include_router(audio_process_router, prefix="/api/process/audio", tags=["Audio Processing"])
app.include_router(main_controller, prefix="/api/process", tags=["Process Controller"])
app.include_router(report_router, prefix="/api/report", tags=["Report"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
