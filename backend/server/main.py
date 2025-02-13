# uvicorn main:app --reload (to start the server)

from fastapi import FastAPI
from controllers.TaskAssignController import router
from dotenv import load_dotenv
from routers import auth  # Add this line

import os

load_dotenv()  # Load environment variables from .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

app = FastAPI(title="Presently Backend")

# Include the router from TaskAssignController
app.include_router(router)

app.include_router(auth.router, prefix="/api/auth")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

