FILLER_WORDS = {
    "uh", "um", "like", "you know", "hmm", "er", "ah", "uhh", "well", "so", 
    "basically", "literally", "actually", "sort of", "kind of"
}

# Speech rate guidelines (words per minute)
SPEECH_RATE = {
    "TOO_SLOW": 120,
    "OPTIMAL_MIN": 120,
    "OPTIMAL_MAX": 160,
    "TOO_FAST": 160
}

# Scoring weights
SCORING_WEIGHTS = {
    "FILLER_WORDS": 0.3,
    "SPEECH_RATE": 0.3,
    "CLARITY": 0.4
}