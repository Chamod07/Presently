from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from services.storage_service import upload_to_supabase
from .auth import get_current_user

router = APIRouter()

@router.post("/upload/")
async def upload_video(file: UploadFile = File(...), user = Depends(get_current_user)):
    if file.content_type not in ["video/mp4", "video/mov"]:
        raise HTTPException(status_code=400, detail="Invalid file type")
    
    # Save file temporarily
    temp_file_path = f"/tmp/{file.filename}"
    with open(temp_file_path, "wb") as temp_file:
        temp_file.write(await file.read())

    # Upload to Supabase
    supabase_url = upload_to_supabase(temp_file_path, file.filename)

    return {"message": "File uploaded successfully", "url": supabase_url}
    