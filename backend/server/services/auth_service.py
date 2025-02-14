from fastapi.security import OAuth2PasswordBearer
from supabase import create_client
import os

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

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
