import os
from dotenv import load_dotenv
import requests
from similarity_calculator import generate_feature_vector, cosine_similarity, SIMILARITY_THRESHOLD
from typing import List, Dict, Any

# Load environment variables (Make sure you have SUPABASE_URL and SUPABASE_KEY in your .env)
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def _fetch_table_data(table_name: str, query_params: dict = None) -> List[Dict[str, Any]]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    url = f"{SUPABASE_URL}/rest/v1/{table_name}"
    try:
        response = requests.get(url, headers=HEADERS, params=query_params)
        if response.status_code == 200:
            return response.json()
    except Exception as e:
        print(f"Error fetching from {table_name}: {e}")
    return []

def _fetch_user_full_profile(user_id: str) -> Dict[str, Any]:
    """
    Helper to fetch a single user's aggregated data from various tables via REST API.
    """
    user_res = _fetch_table_data("users", {"id": f"eq.{user_id}"})
    if not user_res:
        return None
    
    user_data = user_res[0]
    
    # Fetch related data
    user_data['skills'] = _fetch_table_data("user_skills", {"user_id": f"eq.{user_id}"})
    user_data['experiences'] = _fetch_table_data("experiences", {"user_id": f"eq.{user_id}"})
    user_data['quiz_attempts'] = _fetch_table_data("quiz_attempts", {"user_id": f"eq.{user_id}"})
    user_data['issues_posted'] = _fetch_table_data("issues", {"author_id": f"eq.{user_id}"})
    user_data['issues_solved'] = _fetch_table_data("issues", {"status": "eq.resolved", "author_id": f"eq.{user_id}"})
    user_data['events'] = _fetch_table_data("events", {"host_id": f"eq.{user_id}"})
    
    return user_data

def fetch_recommendations(current_user_id: str) -> List[Dict[str, Any]]:
    """
    Provides the top 10 recommended users for the current user based on cosine similarity.
    """
    if not SUPABASE_URL: return []

    # 1. Fetch current user
    current_user = _fetch_user_full_profile(current_user_id)
    if not current_user:
        return []
        
    current_vector = generate_feature_vector(current_user)

    # 2. Fetch all other users
    other_users = _fetch_table_data("users", {"id": f"neq.{current_user_id}", "select": "id,full_name,title,description,degree"})

    # 3. Calculate similarities
    scored_users = []
    for other in other_users:
        other_id = other.get('id')
        other_full_profile = _fetch_user_full_profile(other_id)
        
        if other_full_profile:
            other_vector = generate_feature_vector(other_full_profile)
            score = cosine_similarity(current_vector, other_vector)
            
            # Extract names of skills for the UI payload
            skills_names = [s.get('skill_name', '') for s in other_full_profile.get('skills', []) if s.get('skill_name')]
            
            # Extract degree from education
            education_list = other_full_profile.get('education', [])
            degree_str = other.get('degree') or (education_list[0].get('degree') if education_list else 'Student')
            
            # Calculate initials
            full_name = other.get('full_name') or other.get('name') or 'User'
            initials = ''.join([n[0] for n in full_name.split()[:2]]).upper()

            if score > SIMILARITY_THRESHOLD:
                scored_users.append({
                    "user_id": other_id,
                    "name": full_name,
                    "title": other.get('title', 'Collaborator'),
                    "description": other.get('description', 'No bio available.'),
                    "degree": degree_str,
                    "skills": skills_names,
                    "rating": round(4.0 + (score * 1.0), 1), # Map similarity to a 4.0-5.0 rating
                    "distance": f"{round(1.0 + (1.0 - score) * 10, 1)} km", # Map similarity to distance
                    "initials": initials,
                    "mentorships": other_full_profile.get('reputation', 12),
                    "match_score": round(score, 3) 
                })

    # 4. Sort and Limit
    scored_users.sort(key=lambda x: x['match_score'], reverse=True)
    return scored_users[:10]

def record_like(current_user_id: str, liked_user_id: str) -> (bool, bool):
    """
    Records a like action. If mutual, returns is_match=True.
    """
    if not SUPABASE_URL: return False, False
    
    try:
        # Check for mutual like first (did the other user already like me?)
        match_params = {
            "user_id": f"eq.{liked_user_id}",
            "matched_user_id": f"eq.{current_user_id}"
        }
        reciprocal_likes = _fetch_table_data("matches", match_params)
        is_match = len(reciprocal_likes) > 0

        # Calculate score for the new record
        u1_prof = _fetch_user_full_profile(current_user_id)
        u2_prof = _fetch_user_full_profile(liked_user_id)
        
        score = 0.0
        if u1_prof and u2_prof:
            v1 = generate_feature_vector(u1_prof)
            v2 = generate_feature_vector(u2_prof)
            score = cosine_similarity(v1, v2)

        # Insert the like record via REST
        url = f"{SUPABASE_URL}/rest/v1/matches"
        payload = {
            "user_id": current_user_id,
            "matched_user_id": liked_user_id,
            "match_score": score
        }
        res = requests.post(url, headers=HEADERS, json=payload)
        
        success = res.status_code in (200, 201)
        return success, is_match
    except Exception as e:
        print(f"Error recording match: {e}")
        return False, False
