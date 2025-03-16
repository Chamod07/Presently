from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query
from services.storage_service import upload_to_supabase, get_video_public_url
from .auth import get_current_user
from services import storage_service

router = APIRouter()

@router.post("/upload/")
async def upload_video(
    file: UploadFile = File(...),
    report_id: str = Query(..., description="Report ID to link the video to"),
    user = Depends(get_current_user)
):
    if file.content_type not in ["video/mp4", "video/mov"]:
        raise HTTPException(status_code=400, detail="Invalid file type")
    
    # Generate a unique filename using report_id
    filename = f"{report_id}/{file.filename}"
    
    # Save file temporarily
    temp_file_path = f"/tmp/{file.filename}"
    with open(temp_file_path, "wb") as temp_file:
        temp_file.write(await file.read())

    # Upload to Supabase
    bucket_name = "videos"
    path = f"users/{user.id}/{filename}"
    
    # Upload the file
    supabase_url = upload_to_supabase(temp_file_path, path, bucket_name)
    
    # Get the public URL
    public_url = get_video_public_url(bucket_name, path)
    
    # Update the UserReport record with the video URL
    try:
        response = storage_service.supabase.table("UserReport").update({
            "videoUrl": public_url
        }).eq("reportId", report_id).execute()
        
        if response.error:
            raise HTTPException(status_code=500, detail=f"Error updating report: {response.error}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error linking video to report: {str(e)}")

    return {
        "message": "File uploaded successfully and linked to report",
        "url": public_url
    }
