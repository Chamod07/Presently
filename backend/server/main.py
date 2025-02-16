# uvicorn main:app --reload (to start the server)

from dotenv import load_dotenv
import os

load_dotenv()  # Load environment variables from .env

from fastapi import FastAPI
from controllers.task_assign_controller import router
from routers import auth, upload

load_dotenv()  # Load environment variables from .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

app = FastAPI(title="Presently Backend")

# Include the router from TaskAssignController
app.include_router(router)
app.include_router(auth.router, prefix="/api/auth")
app.include_router(upload.router)

if __name__ == "__main__":

    print("SUPABASE_URL", SUPABASE_URL)
    print("SUPABASE_KEY", SUPABASE_KEY)

    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

