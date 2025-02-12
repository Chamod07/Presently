from fastapi import FastAPI, APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from services.TaskAssignService import assign_challenges
from models.TaskAssignModel import Challenge
import logging

router = APIRouter()

class Feedback(BaseModel):
    user_id: int
    mistakes: List[str]

@router.post("/get-task", response_model=List[Challenge])
async def assign_challenge(feedback: Feedback):
    try:
        challenges = assign_challenges(feedback.mistakes)
        return challenges
    except Exception as e:
        logging.error(f"Error in /assign-challenge: {e}")
        raise HTTPException(status_code=500, detail=str(e))

