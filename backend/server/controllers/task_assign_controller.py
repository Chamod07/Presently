from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List
from services.task_assign_service import assign_challenges_for_report, get_challenge_count_by_status, get_report_count, get_task_count, get_task_groups_by_user, get_tasks
import logging

router = APIRouter()

class ReportAssignmentResponse(BaseModel):
    report_id: str
    assigned_challenge_ids: List[int]

# API endpoint to assign challenges to a report
@router.post("/assign-challenges", response_model=ReportAssignmentResponse)
async def assign_challenges_endpoint(report_id: str):
    try:
        challenge_ids = assign_challenges_for_report(report_id)
        return ReportAssignmentResponse(report_id=report_id, assigned_challenge_ids=challenge_ids)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# API endpoint to fetch the task groups
@router.get("/reports")
def fetch_task_groups(user_id: str = Query(..., description="userId to filter task groups")):
    try:
        task_groups = get_task_groups_by_user(user_id)
        # return {"task_groups": task_groups}
        return task_groups
    except Exception as e:
        logging.error(f"Error in /task_groups: {e}")
        raise HTTPException(status_code=500, detail=str(e))
     
@router.get("/reports_count")
def fetch_task_group_count(report_id: str = Query(..., description="reportId to count task groups")):
    try:
        task_count = get_report_count(report_id)
        # return {"reportId": report_id, "challengeCount": task_count}
        return task_count
    except Exception as e:
        logging.error(f"Error in /task_groups_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/reports/task_count")
def fetch_task_count(report_id: str = Query(..., description="reportId to count tasks")):
    try:
        task_count = get_task_count(report_id)
        # return {"reportId": report_id, "challengeCount": task_count}
        return task_count
    except Exception as e:
        logging.error(f"Error in /api/task_groups/task_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
# API endpoint to fetch the tasks
@router.get("/reports/tasks")
def fetch_tasks(report_id: str = Query(..., description="reportId to filter tasks")):
    try:
        tasks = get_tasks(report_id)
        # return {"reportId": report_id, "challenges": tasks}
        return tasks
    except Exception as e:
        logging.error(f"Error in /api/task_group/tasks: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/reports/completed_count")
def fetch_completed_challenge_count(report_id: str = Query(..., description="Report ID to count completed challenges")):
    try:
        completed_count = get_challenge_count_by_status(report_id, is_done=True)
        # return {"reportId": report_id, "completedChallenges": completed_count}
        return completed_count

    except Exception as e:
        logging.error(f"Error in /api/task_group/completed_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/reports/pending_count")
def fetch_pending_challenge_count(report_id: str = Query(..., description="Report ID to count pending challenges")):
    try:
        pending_count = get_challenge_count_by_status(report_id, is_done=False)
        # return {"reportId": report_id, "pendingChallenges": pending_count}
        return pending_count
    except Exception as e:
        logging.error(f"Error in /api/task_group/pending_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))