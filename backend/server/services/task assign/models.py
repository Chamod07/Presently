from pydantic import BaseModel
from typing import List

class Challenge(BaseModel):
    id: int
    title: str
    description: str
    instructions: str
    associated_mistakes: List[str]
