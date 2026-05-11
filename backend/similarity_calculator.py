import math
from typing import Dict, List, Any

# Threshold for matching - increased to prevent "global matching"
SIMILARITY_THRESHOLD = 0.15 

# Common stop words to ignore during similarity calculation
STOP_WORDS = {
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', "you're", "you've", "you'll", "you'd",
    'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', "she's", 'her', 'hers',
    'herself', 'it', "it's", 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which',
    'who', 'whom', 'this', 'that', "that'll", 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if',
    'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between',
    'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out',
    'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why',
    'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not',
    'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', "don't", 'should',
    "should've", 'now', 'd', 'll', 'm', 'o', 're', 've', 'y', 'ain', 'aren', "aren't", 'couldn', "couldn't",
    'didn', "didn't", 'doesn', "doesn't", 'hadn', "hadn't", 'hasn', "hasn't", 'haven', "haven't", 'isn', "isn't",
    'ma', 'mightn', "mightn't", 'mustn', "mustn't", 'needn', "needn't", 'shan', "shan't", 'shouldn', "shouldn't",
    'wasn', "wasn't", 'weren', "weren't", 'won', "won't", 'wouldn', "wouldn't", 'working', 'using', 'experience'
}

def generate_keywords(text: str) -> set:
    if not text:
        return set()
    # Basic normalization and stop-word filtering
    words = text.lower().replace(',', ' ').replace('.', ' ').replace('/', ' ').split()
    return set(w for w in words if w not in STOP_WORDS and len(w) > 2)

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
    
    # A. Skills Similarity (Weighted Jaccard)
    s1_v, s1_u = v1['verified_skills'], v1['unverified_skills']
    s2_v, s2_u = v2['verified_skills'], v2['unverified_skills']
    
    all1 = s1_v.union(s1_u)
    all2 = s2_v.union(s2_u)
    
    skill_score = 0.0
    if all1 or all2:
        intersection = all1.intersection(all2)
        union = all1.union(all2)
        
        # Weighted Jaccard: Verified skills have triple weight now
        verified_weight = 3  
        v_intersect = s1_v.intersection(s2_v)
        v_union = s1_v.union(s2_v)
        
        weighted_intersection = len(intersection) + (len(v_intersect) * (verified_weight - 1))
        weighted_union = len(union) + (len(v_union) * (verified_weight - 1))
        
        skill_score = weighted_intersection / weighted_union if weighted_union else 0.0

    # B. Experience Similarity (Weighted Jaccard)
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
        ('junior', 'senior'): 1.5,
        ('junior', 'alumni'): 1.6,
        ('senior', 'junior'): 1.2,
        ('alumni', 'junior'): 1.8,
        ('senior', 'senior'): 1.1,
        ('alumni', 'alumni'): 1.1,
    }
    role_boost = combinations.get((r1, r2), 1.0)

    # D. Academic & Reputation
    quiz_diff = abs(v1['avg_quiz'] - v2['avg_quiz']) / 100.0
    academic_compatibility = 1.0 - quiz_diff
    
    reputation_score = min(v2['reputation'] / 100.0, 1.0)

    # Weighted Average - Skills and Experience are main drivers
    final_score = (skill_score * 0.5) + (exp_score * 0.3) + (academic_compatibility * 0.1) + (reputation_score * 0.1)
    final_score *= role_boost

    return min(final_score, 1.0)

