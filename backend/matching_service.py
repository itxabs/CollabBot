import os
import math
from dotenv import load_dotenv
import requests
from similarity_calculator import generate_feature_vector, calculate_similarity, SIMILARITY_THRESHOLD
from typing import List, Dict, Any

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance in kilometers between two points 
    on the earth (specified in decimal degrees)
    """
    if None in (lat1, lon1, lat2, lon2):
        return 999.0 # Unknown distance
    
    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])

    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 # Radius of earth in kilometers. Use 3956 for miles
    return c * r

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
    user_data['education'] = _fetch_table_data("education", {"user_id": f"eq.{user_id}"})
    
    return user_data

def fetch_recommendations(current_user_id: str, lat: float = None, lng: float = None) -> List[Dict[str, Any]]:
    """
    Provides the top 10 recommended users for the current user based on cosine similarity and physical proximity.
    """
    print(f"--- MATCHING ENGINE: Starting recommendations for {current_user_id} ---")
    if not SUPABASE_URL: 
        print("Error: SUPABASE_URL not configured")
        return []

    # 1. Fetch current user
    current_user = _fetch_user_full_profile(current_user_id)
    if not current_user:
        print(f"Error: Current user {current_user_id} not found in database")
        return []
        
    current_vector = generate_feature_vector(current_user)
    current_lat = lat or current_user.get('latitude')
    current_lng = lng or current_user.get('longitude')
    print(f"Vector generated for {current_user.get('full_name')}")

    # 2. Fetch all other users (Filter active only)
    other_users = _fetch_table_data("users", {
        "id": f"neq.{current_user_id}",
        "deleted_at": "is.null"
    })
    print(f"Found {len(other_users)} other users to compare.")

    # 3. Calculate similarities
    scored_users = []
    for other in other_users:
        other_id = other.get('id')
        other_full_profile = _fetch_user_full_profile(other_id)
        
        if other_full_profile:
            other_vector = generate_feature_vector(other_full_profile)
            similarity_score = calculate_similarity(current_vector, other_vector)
            
            # Location score
            other_lat = other.get('latitude')
            other_lng = other.get('longitude')
            dist = haversine(current_lat, current_lng, other_lat, other_lng)
            
            # Distance impact: closer is significantly better if location is provided
            dist_score = 1.0 / (1.0 + (dist / 10.0)) # 10km radius for decent score
            
            # Skill/Experience weight is 70%, proximity is 30% if near
            if current_lat and other_lat:
                final_score = (similarity_score * 0.7) + (dist_score * 0.3)
            else:
                final_score = similarity_score

            # UI data extraction
            skills_names = [s.get('skill_name', '') for s in other_full_profile.get('skills', [])]
            verified_count = sum(1 for s in other_full_profile.get('skills', []) if s.get('is_verified'))
            
            education_list = other_full_profile.get('education', [])
            degree_str = other.get('degree') or (education_list[0].get('degree') if education_list else 'Collaborator')
            
            full_name = other.get('full_name') or 'User'
            initials = ''.join([n[0] for n in full_name.split()[:2]]).upper()

            if final_score >= SIMILARITY_THRESHOLD:
                scored_users.append({
                    "user_id": other_id,
                    "name": full_name,
                    "title": other.get('role', 'Collaborator'),
                    "description": other.get('description') or f"Matching on {len(skills_names)} shared skills.",
                    "degree": degree_str,
                    "skills": skills_names[:4], # Show top 4
                    "verified_skills_count": verified_count, # Badge count
                    "rating": round(4.0 + (final_score * 1.0), 1),
                    "distance": f"{round(dist, 1)} km" if dist < 900 else "Nearby",
                    "initials": initials,
                    "mentorships": other.get('reputation', 0),
                    "match_score": round(final_score, 3) 
                })

    # 4. Sort by score
    scored_users.sort(key=lambda x: x['match_score'], reverse=True)
    print(f"Matching complete. Returning {len(scored_users)} recommendations.")
    return scored_users[:10]

def record_like(current_user_id: str, liked_user_id: str) -> (bool, bool):
    """
    Records a like action. If mutual, returns is_match=True.
    """
    if not SUPABASE_URL: return False, False
    
    try:
        # Check for mutual like
        match_params = {
            "user_id": f"eq.{liked_user_id}",
            "matched_user_id": f"eq.{current_user_id}"
        }
        reciprocal_likes = _fetch_table_data("matches", match_params)
        is_match = len(reciprocal_likes) > 0

        # Insert match record
        url = f"{SUPABASE_URL}/rest/v1/matches"
        payload = {
            "user_id": current_user_id,
            "matched_user_id": liked_user_id
        }
        res = requests.post(url, headers=HEADERS, json=payload)
        
        success = res.status_code in (200, 201)
        return success, is_match
    except Exception as e:
        print(f"Error recording match: {e}")
        return False, False
