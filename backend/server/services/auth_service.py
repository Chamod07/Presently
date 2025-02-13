from jose import jwt, JWTError
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer
import os

security = HTTPBearer()

SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")  # Get this from your Supabase settings

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SUPABASE_JWT_SECRET, algorithms=["HS256"])
        return payload  # Return decoded token payload if valid
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
