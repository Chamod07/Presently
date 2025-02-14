from supabase import create_client
import os

def create_session_handler():
    supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
    return supabase.auth.get_session()