import math
from typing import Dict, List, Any

# Threshold for matching
# Lowered from 0.5 to 0.0 so that test users with empty profiles still show up in the UI.
SIMILARITY_THRESHOLD = 0.0 

def generate_feature_vector(user_data: Dict[str, Any]) -> List[float]:
    """
    Converts a user dictionary loosely containing data from Supabase
    into a structured numerical feature vector for cosine similarity matching.
    """
    
    # Base value to ensure magnitude is never completely 0
    # Everyone gets a base 0.1 match score just for existing!
    base_val = 0.1
    
    # 1. Skills Count (Normalize slightly. Max expected around 20)
    skills = user_data.get('skills', [])
    skills_val = len(skills) / 20.0 

    # 2. Experience Years (Normalize roughly assuming max relevant is 15 years)
    experience = user_data.get('experiences', [])
    exp_val = len(experience) / 10.0

    # 3. Quiz Score
    quiz_attempts = user_data.get('quiz_attempts', [])
    avg_quiz = 0.0
    if quiz_attempts:
        scores = [q.get('score', 0) for q in quiz_attempts if q.get('score') is not None]
        if scores:
            avg_quiz = sum(scores) / len(scores)
            
    quiz_val = avg_quiz / 100.0  # Assumes score is 0-100

    # 4. Activity: Issues Posted and Solved
    issues_posted = user_data.get('issues_posted', [])
    issues_solved = user_data.get('issues_solved', [])
    
    posted_val = len(issues_posted) / 50.0 
    solved_val = len(issues_solved) / 50.0

    # 5. Events Participation
    events = user_data.get('events', [])
    events_val = len(events) / 30.0

    vector = [
        base_val,
        skills_val,
        exp_val,
        quiz_val,
        posted_val,
        solved_val,
        events_val
    ]
    
    return vector

def cosine_similarity(v1: List[float], v2: List[float]) -> float:
    """
    Calculates the cosine similarity between two vectors.
    Returns 0.0 to 1.0.
    """
    if not v1 or not v2 or len(v1) != len(v2):
        return 0.0
        
    dot_product = sum(x * y for x, y in zip(v1, v2))
    magnitude1 = math.sqrt(sum(x * x for x in v1))
    magnitude2 = math.sqrt(sum(x * x for x in v2))
    
    if magnitude1 == 0 or magnitude2 == 0:
        return 0.0
        
    return dot_product / (magnitude1 * magnitude2)
