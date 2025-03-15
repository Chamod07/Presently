from typing import Dict, Any, Optional, List
from pydantic import BaseModel

class BaseReport(BaseModel):
    reportId: str
    reportTopic: str
    createdAt: str
    userId: Optional[str] = None

class UserReport(BaseReport):
    scoreContext: Optional[float] = None
    subScoresContext: Optional[Dict[str, Any]] = None
    weaknessTopicsContext: Optional[List[Dict[str, Any]]] = None
    scoreGrammar: Optional[float] = None
    subScoresGrammar: Optional[Dict[str, Any]] = None
    weaknessTopicsGrammar: Optional[List[Dict[str, Any]]] = None
    scoreBodyLanguage: Optional[float] = None
    scoreEmotions: Optional[float] = None
    scoreVoice: Optional[float] = None
    resources: Optional[Dict[str, Any]] = None
    feedback: Optional[Dict[str, Any]] = None
