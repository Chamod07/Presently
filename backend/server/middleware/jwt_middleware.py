from fastapi import HTTPException, Depends, Request
from jose import JWTError, jwt
import os

async def verify_supabase_jwt(request: Request):
    token = request.headers.get("Authorization")
    if not token:
        raise HTTPException(status_code=403, detail="Authorization header missing")

    try:
        payload = jwt.decode(
            token.split(" ")[1],  # Remove "Bearer " prefix
            os.getenv("SUPABASE_KEY"),
            algorithms=["HS256"],
            options={"verify_aud": False, "verify_iss": False}
        )
        return payload
    except JWTError as e:
        raise HTTPException(status_code=401, detail=str(e))

async def get_current_user(request: Request, payload: dict = Depends(verify_supabase_jwt)):
    #this function is to get the user id,
    return payload