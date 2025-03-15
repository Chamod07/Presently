# uvicorn main:app --reload (to start the server)

from dotenv import load_dotenv
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from controllers.task_assign_controller import router as task_assign_router
from controllers.context_analysis_controller import router as context_router
from controllers.grammar_analysis_controller import router as grammar_router
from controllers.body_language_analysis_controller import router as body_language_router
from controllers.voice_analysis_controller import router as voice_router
from controllers.video_process_controller import router as video_process_router
from controllers.audio_process_controller import router as audio_process_router
from controllers.main_process_controller import router as main_controller
from routers import auth, upload


load_dotenv()  # Load environment variables from .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
# SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

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

app.include_router(task_assign_router, prefix="/api/task-assign", tags=["task assign"])
app.include_router(auth.router, prefix="/api/auth")
app.include_router(upload.router)
app.include_router(grammar_router, prefix="/api/analyser/grammar", tags=["grammar"])
app.include_router(context_router, prefix="/api/analyser/context", tags=["context"])
app.include_router(body_language_router, prefix="/api/analyser/body-language", tags=["Body Language Analysis"])
app.include_router(voice_router, prefix="/api/analyser/voice", tags=["Voice Analysis"])
app.include_router(video_process_router, prefix="/api/process/video", tags=["Video Processing"])
app.include_router(audio_process_router, prefix="/api/process/audio", tags=["Audio Processing"])
app.include_router(main_controller, prefix="/api/process/main", tags=["Main Processing"])


if __name__ == "__main__":

    print("SUPABASE_URL", SUPABASE_URL)
    print("SUPABASE_KEY", SUPABASE_KEY)

    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
