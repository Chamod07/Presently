from pydantic import BaseModel, Field
from typing import List, Optional


class ResourceLink(BaseModel):
    url: str
    title: Optional[str] = None

class Feedback(BaseModel):
    title: str
    description: str

class UserReport(BaseModel):
    id: Optional[int] = None
    #created_at: Optional[datetime.now()] = None
    score_body_language: float
    score_emotions: float
    score_voice: float
    feedback: Feedback
    resources: List[ResourceLink]


