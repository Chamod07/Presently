from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from supabase import create_client
from pydantic import BaseModel
import os

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Supabase configuration
# SUPABASE_URL = os.getenv("SUPABASE_URL")
# SUPABASE_KEY = os.getenv("SUPABASE_KEY")
# supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def get_supabase():
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

async def get_current_user(token: str = Depends(oauth2_scheme)):
    supabase = get_supabase()
    try:
        user = supabase.auth.get_user(token)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid authentication")
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

class SignInRequest(BaseModel):
    email: str
    password: str

class GoogleSignInRequest(BaseModel):
    id_token: str
    access_token: str

@router.post("/signin/email")
async def proxy_email_signin(request: SignInRequest):
    supabase = get_supabase()
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
