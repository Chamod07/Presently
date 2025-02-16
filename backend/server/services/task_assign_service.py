import logging
import os
from typing import List, Dict
from dotenv import load_dotenv
from supabase import create_client, Client
from models.task_assign_model import Challenge

load_dotenv()  # Load environment variables from .env

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def fetch_challenges() -> List[Challenge]:
    response = supabase.table("Challenges").select("*").execute()
    data = response.data
    challenges = []
    for item in data:
        try:
            logging.info(f"Processing row: {item}")
            challenge = Challenge(**item)
            challenges.append(challenge)
        except Exception as e:
            logging.error(f"Error parsing item {item}: {e}")
    return challenges

def build_mapping(challenges: List[Challenge]) -> Dict[str, List[Challenge]]:
    mapping: Dict[str, List[Challenge]] = {}
    for challenge in challenges:
        for mistake in challenge.associatedMistakes:
            mapping.setdefault(mistake, []).append(challenge)
    return mapping


def assign_challenges(feedback_mistakes: List[str]) -> List[Challenge]:
    challenges = fetch_challenges()
    if not challenges:
        raise Exception("No challenges available from the database.")

    mapping: Dict[str, List[Challenge]] = build_mapping(challenges)

    # Count occurrences of each mistake
    mistake_counts: Dict[str, int] = {}
    for mistake in feedback_mistakes:
        mistake_counts[mistake] = mistake_counts.get(mistake, 0) + 1

    assigned = {}
    for mistake, count in mistake_counts.items():
        if count >= 5 and mistake in mapping:  # Assign only if mistake occurs 5+ times
            for challenge in mapping[mistake]:
                assigned[challenge.id] = challenge

    if not assigned:
        raise Exception("No matching challenges found for given mistakes")
    
    return list(assigned.values())

# to fetch the task groups
def get_task_groups_by_user(user_id: str):
    response = supabase.table("UserReport").select("reportName").eq("userId", user_id).execute()
    
    if hasattr(response, "data") and response.data:
        report_names = [item.get("reportName") for item in response.data if "reportName" in item]
        return report_names
    
    if hasattr(response, "error") and response.error:
        raise Exception(f"Error fetching task groups: {response.error}")

    # to return and emty list if no data is found
    return []  
