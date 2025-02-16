from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List
from services.task_assign_service import assign_challenges, get_task_groups_by_user
from models.task_assign_model import Challenge
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

# API endpoint to fetch the task groups
@router.get("/task-groups", tags=["frontend"])
def fetch_task_groups(user_id: str = Query(..., description="User ID to filter task groups")):
    try:
        task_groups = get_task_groups_by_user(user_id)
        # return {"task_groups": task_groups}
        return task_groups
    except Exception as e:
        logging.error(f"Error in /task-groups: {e}")
        raise HTTPException(status_code=500, detail=str(e))