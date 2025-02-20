from typing import Dict, Any
from pydantic import BaseModel

class UserReport(BaseModel):
    reportId: str
    reportTopic: str
    createdAt: str  # ISO format
    userId: str

    #Context
    scoreContext: float
    subScoresContext: Dict[str, float]
    weaknessTopicsContext: list[Dict[str, Any]]

    #Grammar
    scoreGrammar: float
    subScoresGrammar: Dict[str, Any]
    weaknessTopicsGrammar: list[Dict[str, Any]]