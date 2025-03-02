from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from typing import List
from services.task_assign_service import *
from services.auth_service import get_current_user_id
import logging

router = APIRouter()

class ReportAssignmentResponse(BaseModel):
    report_id: str
    assigned_challenge_ids: List[int]

# API endpoint to assign challenges to a report
@router.post("/assign_challenges", response_model=ReportAssignmentResponse)
async def assign_challenges_endpoint(report_id: str, user_id: str = Depends(get_current_user_id)):
    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
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
    
@router.get("/report/task_count")
def fetch_task_count(
    report_id: str = Query(..., description="reportId to count tasks"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        task_count = get_task_count(report_id)
        return {"reportId": report_id, "taskCount": task_count}
    except Exception as e:
        logging.error(f"Error in /report/task_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/report/progress")
def fetch_task_group_progress(
    report_id: str = Query(..., description="Report ID for the task group"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        progress = get_task_group_progress(report_id)
        return {"reportId": report_id, "progressPercentage": progress}
    except Exception as e:
        logging.error(f"Error in /report/progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/overall-progress")
def fetch_overall_progress(user_id: str = Depends(get_current_user_id)):
    try:
        overall_progress = get_overall_progress(user_id)
        return {"userId": user_id, "overallProgressPercentage": overall_progress}
    except Exception as e:
        logging.error(f"Error in /overall-progress: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
# API endpoint to fetch the tasks
@router.get("/report/task/all")
def fetch_all_tasks(
    report_id: str = Query(..., description="Report ID to fetch all tasks"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        tasks = get_tasks(report_id)
        return {"reportId": report_id, "tasks": tasks}
    except Exception as e:
        logging.error(f"Error in /report/task/all: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/report/task/todo")
def fetch_todo_tasks(
    report_id: str = Query(..., description="Report ID to fetch tasks to do"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        tasks = get_tasks(report_id)
        todo_tasks = [task for task in tasks if not task.get("isDone")]
        return {"reportId": report_id, "tasks": todo_tasks}
    except Exception as e:
        logging.error(f"Error in /report/task/todo: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/report/task/completed")
def fetch_completed_tasks(
    report_id: str = Query(..., description="Report ID to fetch completed tasks"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        tasks = get_tasks(report_id)
        completed_tasks = [task for task in tasks if task.get("isDone")]
        return {"reportId": report_id, "tasks": completed_tasks}
    except Exception as e:
        logging.error(f"Error in /report/task/completed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/report/completed_count")
def fetch_completed_challenge_count(
    report_id: str = Query(..., description="Report ID to count completed challenges"),
    user_id: str = Depends(get_current_user_id)):

    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        completed_count = get_challenge_count_by_status(report_id, is_done=True)
        return completed_count
    except Exception as e:
        logging.error(f"Error in /report/completed_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/report/pending_count")
def fetch_pending_challenge_count(
    report_id: str = Query(..., description="Report ID to count pending challenges"),
    user_id: str = Depends(get_current_user_id)):
    
    try:
        # Verify user has access to this report
        if not user_has_access_to_report(report_id, user_id):
            raise HTTPException(status_code=403, detail="You don't have access to this report")
            
        pending_count = get_challenge_count_by_status(report_id, is_done=False)
        return pending_count
    except Exception as e:
        logging.error(f"Error in /report/pending_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))