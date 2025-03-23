from fastapi import APIRouter, HTTPException, Query, Depends, Body
from pydantic import BaseModel
from typing import List
from services.task_assign_service import *
from services.auth_service import get_current_user_id
import logging

router = APIRouter()

class ReportAssignmentResponse(BaseModel):
    report_id: str
    assigned_challenge_ids: List[int]

class TaskGroupDetailsResponse(BaseModel):
    reportId: str
    session_name: str
    progress: float
    taskCount: int
    completedCount: int
    pendingCount: int
    tasks: dict

class TaskUpdateRequest(BaseModel):
    reportId: str
    taskId: str
    isDone: bool

# API endpoint to assign challenges to a report
@router.post("/assign_challenges", response_model=ReportAssignmentResponse)
async def assign_challenges_endpoint(report_id: str):
    try:       
        challenge_ids = assign_challenges_for_report(report_id)
        return ReportAssignmentResponse(report_id=report_id, assigned_challenge_ids=challenge_ids)
    except Exception as e:
        logging.error(f"Error in /assign-challenges: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# API endpoint to fetch the task groups
@router.get("/report")
def fetch_task_groups(user_id: str = Depends(get_current_user_id)):
    try:
        task_groups = get_task_groups_by_user(user_id)
        return task_groups
    except Exception as e:
        logging.error(f"Error in /report: {e}")
        raise HTTPException(status_code=500, detail=str(e))
 
@router.get("/report_count")
def fetch_task_group_count(user_id: str = Depends(get_current_user_id)):
    try:
        task_count = get_report_count(user_id)
        return task_count
    except Exception as e:
        logging.error(f"Error in /report_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/overall-progress")
def fetch_overall_progress(user_id: str = Depends(get_current_user_id)):
    try:
        overall_progress = get_overall_progress(user_id)
        return {"userId": user_id, "overallProgressPercentage": overall_progress}
    except Exception as e:
        logging.error(f"Error in /overall-progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Consolidated API endpoint to get all details for a task group
@router.get("/report/details", response_model=TaskGroupDetailsResponse)
def get_task_group_details_endpoint(
    report_id: str = Query(..., description="Report ID to fetch all details"),
    user_id: str = Depends(get_current_user_id)):
    
    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        task_group_details = get_task_group_details(report_id)
        return task_group_details
    except Exception as e:
        logging.error(f"Error in /report/details: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# API endpoint to update task status
@router.post("/report/task/update")
async def update_task_status_endpoint(
    update_data: TaskUpdateRequest = Body(...),
    user_id: str = Depends(get_current_user_id)
):
    try:
        report_id = update_data.reportId
        task_id = update_data.taskId
        is_done = update_data.isDone
        
        if not report_id or not task_id:
            raise HTTPException(status_code=400, detail="Missing required fields: reportId or taskId")
            
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        result = update_task_status(report_id, task_id, is_done)
        if result:
            return {"success": True, "message": "Task status updated successfully"}
        else:
            raise HTTPException(status_code=404, detail="Task not found or status update failed")
            
    except Exception as e:
        logging.error(f"Error in /report/task/update: {e}")
        raise HTTPException(status_code=500, detail=str(e))