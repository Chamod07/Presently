from fastapi import APIRouter, Depends, HTTPException
from supabase import create_client
from pydantic import BaseModel
import os

router = APIRouter()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

class SignInRequest(BaseModel):
    email: str
    password: str

class GoogleSignInRequest(BaseModel):
    id_token: str
    access_token: str

@router.post("/signin/email")
async def proxy_email_signin(request: SignInRequest):
    try:
        res = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        return {"session": res.session.dict(), "error": None}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/signin/google")
async def proxy_google_signin(request: GoogleSignInRequest):
    try:
        res = supabase.auth.sign_in_with_id_token(
            provider="google",
            id_token=request.id_token,
            access_token=request.access_token
        )
        return {"session": res.session.dict(), "error": None}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
