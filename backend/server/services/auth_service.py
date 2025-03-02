import logging
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import create_client
import os

# Replace OAuth2PasswordBearer with HTTPBearer which is more appropriate for JWT tokens
security = HTTPBearer()

def get_supabase():
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    supabase = get_supabase()
    try:
        token = credentials.credentials
        user = supabase.auth.get_user(token)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid authentication")
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

async def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)):
    supabase = get_supabase()
    try:
        # Get user from token
        token = credentials.credentials
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Invalid authentication credentials"
            )
        
        # Return the user ID
        return user_response.user.id
    except Exception as e:
        logging.error(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid authentication credentials"
        )