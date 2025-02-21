import logging
import os
from typing import List, Dict
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()  # Load environment variables from .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# to fetch the task groups
def get_task_groups_by_user(user_id: str):
    response = supabase.table("UserReport").select("reportTopic").eq("userId", user_id).execute()
    
    if hasattr(response, "data") and response.data:
        report_names = [item.get("reportTopic") for item in response.data if "reportTopic" in item]
        return report_names
    
    if hasattr(response, "error") and response.error:
        raise Exception(f"Error fetching task groups: {response.error}")

    # to return and emty list if no data is found
    return []  

# to count the number of reports linked to the given userId
def get_report_count(user_id: str):
    response = supabase.table("UserReport").select("reportId", count="exact").eq("userId", user_id).execute()

    if hasattr(response, "error") and response.error:
        raise Exception(f"Error fetching report count: {response.error}")

    # to return the count of reports
    if hasattr(response, "count"):
        return response.count  # Returns the exact count of reports

    # to default to 0 if no challenges are found
    return 0

# to count the number of challenges linked to the given reportId
def get_task_count(report_id: str):
    response = supabase.table("TaskGroupChallenges").select("id", count="exact").eq("reportId", report_id).execute()

    if hasattr(response, "error") and response.error:
        raise Exception(f"Error fetching task count: {response.error}")

    # to return the count of challenges
    if hasattr(response, "count"):
        return response.count  # Returns the exact count of challenges

    # to default to 0 if no challenges are found
    return 0

# to fetch the challenges
def get_tasks(report_id: str):
    # Get challenge IDs linked to the reportId
    task_group_response = supabase.table("TaskGroupChallenges").select("challengeId").eq("reportId", report_id).execute()

    # Handle errors in fetching task group challenges
    if hasattr(task_group_response, "error") and task_group_response.error:
        raise Exception(f"Error fetching challenge IDs: {task_group_response.error}")

    challenge_ids = [item["challengeId"] for item in task_group_response.data if "challengeId" in item]

    if not challenge_ids:
        return []  # Return empty list if no challenges are assigned

    # Fetch challenge titles from Challenges table
    # challenges_response = supabase.table("Challenges").select("id, title").in_("id", challenge_ids).execute()
    challenges_response = supabase.table("Challenges").select("id, title").in_("id", challenge_ids).execute()

    # Handle errors in fetching challenges
    if hasattr(challenges_response, "error") and challenges_response.error:
        raise Exception(f"Error fetching challenge titles: {challenges_response.error}")

    # Extract and return list of challenge titles
    # return [{"id": item["id"], "title": item["title"]} for item in challenges_response.data if "id" in item and "title" in item]
    return [item["title"] for item in challenges_response.data if "id" in item]

def get_challenge_count_by_status(report_id: str, is_done: bool):
    # Query to count challenges with the given status (isDone=True or isDone=False)
    response = supabase.table("TaskGroupChallenges").select("id", count="exact").eq("reportId", report_id).eq("isDone", is_done).execute()

    if hasattr(response, "error") and response.error:
        raise Exception(f"Error fetching challenge count: {response.error}")

    if hasattr(response, "count"):
        return response.count  

    # to return 0 if no challenges are found
    return 0  

# to get the user mistake list from the UserReport table
def get_user_mistakes(report_id: str) -> List[str]:
  
    response = supabase.table("UserReport").select("subScoresContext").eq("reportId", report_id).execute()
    if not response.data or len(response.data) == 0:
        raise Exception(f"No report found with id: {report_id}")
    
    report = response.data[0]
    mistakes = report.get("subScoresContext", [])
    logging.info(f"Fetched mistakes for report {report_id}: {mistakes}")
    return mistakes


#to fetch the challenges from the Challenges table with their ID and associated mistakes
def fetch_challenges() -> List[Dict]:
 
    response = supabase.table("Challenges").select("id, associatedMistakes").execute()
    if not response.data:
        raise Exception("No challenges found in the Challenges table.")
    logging.info(f"Fetched challenges: {response.data}")
    return response.data

#to map the relevent challenges 
def build_mapping(challenges: List[Dict]) -> Dict[str, List[int]]:
   
    mapping: Dict[str, List[int]] = {}
    for challenge in challenges:
        challenge_id = challenge.get("id")
        associated_mistakes = challenge.get("associatedMistakes", [])
        for mistake in associated_mistakes:
            mapping.setdefault(mistake, []).append(challenge_id)
    logging.info(f"Built mapping: {mapping}")
    return mapping

# to insert data into the TaskGroupChallenges table
def insert_task_group_challenges(report_id: str, challenge_ids: List[int]) -> None:
 
    for challenge_id in challenge_ids:
        # Insert a row for each challenge assignment.
        try:
            response = supabase.table("TaskGroupChallenges").insert({
                "reportId": report_id,
                "challengeId": challenge_id
            }).execute()

            if hasattr(response, 'error') and response.error:
                logging.error(f"Error inserting assignment for challenge {challenge_id}: {response.error}")
                raise Exception(f"Error inserting assignment for challenge {challenge_id}")
            elif not hasattr(response, 'data'):
                logging.error(f"No data returned for challenge {challenge_id}: {response}")
                raise Exception(f"No data returned for challenge {challenge_id}")

        except Exception as e:
            logging.error(f"Exception inserting assignment for challenge {challenge_id}: {e}")
            raise e

    logging.info(f"Inserted TaskGroupChallenges for report {report_id} with challenges {challenge_ids}")

def assign_challenges_for_report(report_id: str, threshold: int = 5) -> List[int]:
    
    # Fetch mistakes from the user report.
    mistakes = get_user_mistakes(report_id)
    
    # Count the occurrences of each mistake.
    mistake_counts: Dict[str, int] = {}
    for mistake in mistakes:
        mistake_counts[mistake] = mistake_counts.get(mistake, 0) + 1
    logging.info(f"Mistake counts for report {report_id}: {mistake_counts}")

    # Fetch challenges and build the mapping.
    challenges = fetch_challenges()
    mapping = build_mapping(challenges)

    # For each mistake meeting the threshold, collect associated challenge ids.
    assigned_challenge_ids = set()
    for mistake, count in mistake_counts.items():
        if count >= threshold and mistake in mapping:
            for challenge_id in mapping[mistake]:
                assigned_challenge_ids.add(challenge_id)
    if not assigned_challenge_ids:
        raise Exception("No matching challenges found that meet the threshold criteria")
    
    assigned_challenge_ids_list = list(assigned_challenge_ids)
    
    # Insert the assignments into TaskGroupChallenges.
    insert_task_group_challenges(report_id, assigned_challenge_ids_list)
    
    return assigned_challenge_ids_list