# uvicorn main:app --reload (to run the server)

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from mapping import assign_challenges

app = FastAPI(title="Task Assigning API")

# for the feedback request
class Feedback(BaseModel):
    user_id: str
    mistakes: List[str]

# for challenge output 
class ChallengeOut(BaseModel):
    id: int
    title: str
    description: str
    instructions: str

@app.post("/assign-challenge", response_model=List[ChallengeOut])
async def assign_challenge(feedback: Feedback):
    challenges = assign_challenges(feedback.mistakes)
    if not challenges:
        raise HTTPException(status_code=404, detail="No challenges found for given mistakes")
    return challenges


