# uvicorn main:app --reload (to start the server)

from dotenv import load_dotenv
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from controllers.task_assign_controller import router as task_assign_router
from controllers.context_analysis_controller import router as context_router
from controllers.grammar_analysis_controller import router as grammar_router
from routers import auth, upload, secure_routes


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
app.include_router(secure_routes.router, prefix="/api") #this endpoint is to test the jwt auth
app.include_router(grammar_router, prefix="/api/analyser/grammar", tags=["grammar"])
app.include_router(context_router, prefix="/api/analyser/context", tags=["context"])

if __name__ == "__main__":

    print("SUPABASE_URL", SUPABASE_URL)
    print("SUPABASE_KEY", SUPABASE_KEY)

    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

