# uvicorn main:app --reload (to run the server)

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from mapping import assign_challenges
from models import Challenge
import logging

app = FastAPI(title="Task Assigning API")

class Feedback(BaseModel):
    user_id: int
    mistakes: List[str]

@app.post("/assign-challenge", response_model=List[Challenge])
async def assign_challenge(feedback: Feedback):
    try:
        challenges = assign_challenges(feedback.mistakes)
        return challenges
    except Exception as e:
        logging.error(f"Error in /assign-challenge: {e}")
        raise HTTPException(status_code=500, detail=str(e))
