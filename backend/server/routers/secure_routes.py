from fastapi import APIRouter, Depends, HTTPException, Request
from services.auth_service import get_current_user

router = APIRouter()

@router.get("/secure")
async def secure_endpoint(request: Request, user: dict = Depends(get_current_user)):
    """
    A sample secure endpoint that requires a valid JWT.
    """
    return {"message": "This is a secure endpoint", "user": user}