import os
from supabase import create_client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
STORAGE_BUCKET_NAME = os.getenv("STORAGE_BUCKET_NAME")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def upload_to_supabase(file_path: str, filename: str) -> str:
    with open(file_path, "rb") as file_data:
        response = supabase.storage.from_(STORAGE_BUCKET_NAME).upload(filename, file_data)

    if response.get("error"):
        raise Exception(f"Error uploading file: {response['error']['message']}")

    public_url = supabase.storage.from_(STORAGE_BUCKET_NAME).get_public_url(filename)
    return public_url
