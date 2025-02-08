import config
import logging
from typing import List, Dict
from supabase import create_client, Client
from models import Challenge


supabase: Client = create_client(config.SUPABASE_URL, config.SUPABASE_KEY)

def fetch_challenges() -> List[Challenge]:
    response = supabase.table("challenges").select("*").execute()
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
        for mistake in challenge.associated_mistakes:
            mapping.setdefault(mistake, []).append(challenge)
    return mapping

# def assign_challenges(feedback_mistakes: List[str]) -> List[Challenge]:
    challenges = fetch_challenges()
    if not challenges:
        raise Exception("No challenges available from the database.")

    mapping: Dict[str, List[Challenge]] = {}
    for challenge in challenges:
        for mistake in challenge.associated_mistakes:
            mapping.setdefault(mistake, []).append(challenge)

    assigned = {}
    for mistake in feedback_mistakes:
        if mistake in mapping:
            for challenge in mapping[mistake]:
                assigned[challenge.id] = challenge
    if not assigned:
        raise Exception("No matching challenges found for given mistakes")
    return list(assigned.values())

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

