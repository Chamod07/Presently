from supabase import create_client
from typing import List
from config.config import SUPABASE_URL, SUPABASE_KEY
from models.user_report_model import UserReport

class UserReportService:
    def __init__(self):
        self.supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    async def create_user_report(self, user_report: UserReport) -> UserReport:
        response = await self.supabase.table("user_report").insert(user_report.dict(exclude={"id","created_at"})).execute()
        if response.error:
            raise Exception(response.error)
        return user_report

    async def fetch_user_reports(self) -> List[UserReport]:
        response = await self.supabase.table("user_report").select("*").execute()
        if response.error:
            raise Exception(response.error)
        return [UserReport(**report) for report in response.data]

    async def fetch_user_report(self, user_report_id: int) -> UserReport:
        response = await self.supabase.table("user_report").select("*").eq("id", user_report_id).execute()
        if response.error:
            raise Exception(response.error)
        data = response.data
        if not data:
            raise Exception(f"User report with id {user_report_id} not found")
        return UserReport(**data[0])


    async def delete_user_report(self, user_report_id: int) -> bool:
        response = await self.supabase.table("user_report").delete().eq("id", user_report_id).execute()
        if response.error:
            raise Exception(response.error)
        return bool(response.data)