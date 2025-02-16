from pydantic import BaseModel, Extra
from typing import List

class Challenge(BaseModel):
    id: int
    title: str
    description: str
    instructions: List[str]         
    associatedMistakes: List[str]    
    points: int                     

# to ignore additional fields if there are any 
class Config:
        extra = Extra.ignore  