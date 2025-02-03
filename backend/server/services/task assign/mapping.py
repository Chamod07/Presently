from typing import List, Dict
from models import Challenge

# list of challenges
challenges: List[Challenge] = [
    Challenge(
        id=1,
        title="Stand straight for 1 minute",
        description="Improve your posture by practicing standing straight.",
        instructions="Find a quiet space, stand with your shoulders back and your head held high for one minute.",
        associated_mistakes=["poor posture", "slouching"]
    ),
    Challenge(
        id=2,
        title="Focus on Deep Breathing",
        description="Enhance focus by practicing deep breathing.",
        instructions="Sit comfortably, close your eyes, and take slow, deep breaths for two minutes.",
        associated_mistakes=["lack of focus", "stress"]
    )
]

# mapping mistakes to challenges
mistake_to_challenges: Dict[str, List[Challenge]] = {}
for challenge in challenges:
    for mistake in challenge.associated_mistakes:
        if mistake not in mistake_to_challenges:
            mistake_to_challenges[mistake] = []
        mistake_to_challenges[mistake].append(challenge)

def assign_challenges(feedback_mistakes: List[str]) -> List[Challenge]:
    
    # Using a dictionary to ensure each challenge is added only once
    assigned = {}
    for mistake in feedback_mistakes:
        if mistake in mistake_to_challenges:
            for challenge in mistake_to_challenges[mistake]:
                assigned[challenge.id] = challenge
    return list(assigned.values())
