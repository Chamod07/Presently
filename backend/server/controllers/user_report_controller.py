from fastapi import APIRouter, Depends, HTTPException
from typing import List
from services.user_report_service import UserReportService
from models.user_report_model import UserReport

router = APIRouter(prefix="/api/user-reports", tags=["user-reports"])

def get_supabase_service() -> UserReportService:
    return UserReportService()

@router.post("/", response_model=UserReport)
async def create_report(
    report: UserReport,
    supabase_service: UserReportService = Depends(get_supabase_service)
):
    return await supabase_service.create_user_report(report)

@router.get("/{report_id}", response_model=UserReport)
async def get_report(
    report_id: int,
    supabase_service: UserReportService = Depends(get_supabase_service)
):
    report = await supabase_service.get_user_report(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return report

@router.get("/", response_model=List[UserReport])
async def get_all_reports(
    supabase_service: UserReportService = Depends(get_supabase_service)
):
    return await supabase_service.get_all_user_reports()

@router.delete("/{report_id}")
async def delete_report(
    report_id: int,
    supabase_service: UserReportService = Depends(get_supabase_service)
):
    success = await supabase_service.delete_user_report(report_id)
    if not success:
        raise HTTPException(status_code=404, detail="Report not found")
    return {"message": "Report deleted successfully"}