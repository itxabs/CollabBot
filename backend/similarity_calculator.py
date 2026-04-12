import math
from typing import Dict, List, Any

# Threshold for matching
SIMILARITY_THRESHOLD = 0.05 

def generate_keywords(text: str) -> set:
    if not text:
        return set()
    # Basic normalization
    return set(text.lower().replace(',', ' ').split())

def generate_feature_vector(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extracts features as a dictionary to allow more flexible comparisons.
    """
    
    # 1. Skills Set (Separating verified vs non-verified)
    skills = user_data.get('skills', [])
    verified_skills = set(s.get('skill_name', '').lower() for s in skills if s.get('is_verified'))
    unverified_skills = set(s.get('skill_name', '').lower() for s in skills if not s.get('is_verified'))

    # 2. Experience Keywords
    exp_keywords = set()
    for exp in user_data.get('experiences', []):
        title = exp.get('title', '')
        desc = exp.get('description', '')
        exp_keywords.update(generate_keywords(title))
        exp_keywords.update(generate_keywords(desc))

    # 3. Quiz Score
    quiz_attempts = user_data.get('quiz_attempts', [])
    avg_quiz = 0.0
    if quiz_attempts:
        scores = [q.get('score', 0) for q in quiz_attempts if q.get('score') is not None]
        if scores:
            avg_quiz = sum(scores) / len(scores)

    # 4. Role
    role = user_data.get('role', 'Junior').lower()

    return {
        "verified_skills": verified_skills,
        "unverified_skills": unverified_skills,
        "exp_keywords": exp_keywords,
        "avg_quiz": avg_quiz,
        "role": role,
        "reputation": user_data.get('reputation', 0)
    }

def calculate_similarity(v1: Dict[str, Any], v2: Dict[str, Any]) -> float:
    """
    Calculates a hybrid similarity score (0.0 to 1.0).
    Verified skills (badges) and Role-matching are prioritized.
    """
    
    # A. Skills Similarity (Jaccard)
    # Give verified skills 2x weight
    s1_v, s1_u = v1['verified_skills'], v1['unverified_skills']
    s2_v, s2_u = v2['verified_skills'], v2['unverified_skills']
    
    # Combined set for Jaccard, but we track verified matches separately
    all1 = s1_v.union(s1_u)
    all2 = s2_v.union(s2_u)
    
    skill_score = 0.0
    if all1 or all2:
        intersection = all1.intersection(all2)
        union = all1.union(all2)
        
        # Base Jaccard
        base_jaccard = len(intersection) / len(union) if union else 0.0
        
        # Verified match boost (if they share a verified skill)
        verified_match = len(s1_v.intersection(s2_v))
        boost = 1.0 + (verified_match * 0.2) # 20% boost per verified skill match
        skill_score = base_jaccard * boost

    # B. Experience Similarity (Jaccard on keywords)
    k1, k2 = v1['exp_keywords'], v2['exp_keywords']
    exp_score = 0.0
    if k1 or k2:
        intersection = k1.intersection(k2)
        union = k1.union(k2)
        exp_score = len(intersection) / len(union) if union else 0.0

    # C. Role-based boost (The "Smart Swap" rules)
    role_boost = 1.0
    r1, r2 = v1['role'], v2['role']
    
    combinations = {
        ('junior', 'senior'): 1.5, # Juniors prioritize Seniors
        ('junior', 'alumni'): 1.6, # Juniors prioritize Alumni
        ('senior', 'junior'): 1.2,
        ('alumni', 'junior'): 1.8, # Alumni matching with Juniors for mentorship
    }
    role_boost = combinations.get((r1, r2), 1.0)

    # D. Academic & Reputation (Academic programs matching)
    quiz_diff = abs(v1['avg_quiz'] - v2['avg_quiz']) / 100.0
    academic_compatibility = 1.0 - quiz_diff
    
    reputation_score = min(v2['reputation'] / 100.0, 1.0) # Boost highly reputable users

    # Weighted Average
    # Skills = 50%, Experience = 30%, Academic/Reputation = 20%
    final_score = (skill_score * 0.5) + (exp_score * 0.3) + (academic_compatibility * 0.1) + (reputation_score * 0.1)
    final_score *= role_boost

    return min(final_score, 1.0)
