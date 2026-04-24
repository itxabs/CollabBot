import os
import math
from datetime import datetime, timedelta
from dotenv import load_dotenv
import requests
from similarity_calculator import generate_feature_vector, calculate_similarity, SIMILARITY_THRESHOLD
from typing import List, Dict, Any, Optional

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

def record_view(viewer_id: str, target_id: str) -> bool:
    """Records a profile view."""
    if not SUPABASE_URL: return False
    payload = {"viewer_id": viewer_id, "target_id": target_id}
    return _upsert_table_data("profile_views", payload, "id")

def haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance in kilometers between two points 
    on the earth (specified in decimal degrees)
    """
    if None in (lat1, lon1, lat2, lon2):
        return None
    
    try:
        lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])
        dlon = lon2 - lon1
        dlat = lat2 - lat1
        a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        r = 6371  # Earth radius in KM
        return c * r
    except:
        return None

def _fetch_table_data(table_name: str, query_params: dict = None) -> List[Dict[str, Any]]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    url = f"{SUPABASE_URL}/rest/v1/{table_name}"
    try:
        response = requests.get(url, headers=HEADERS, params=query_params)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error fetching {table_name}: {response.status_code} {response.text[:200]}")
    except Exception as e:
        print(f"Error fetching from {table_name}: {e}")
    return []

def _upsert_table_data(table_name: str, payload: dict, on_conflict: str) -> bool:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return False
    url = f"{SUPABASE_URL}/rest/v1/{table_name}"
    headers = {**HEADERS, "Prefer": f"resolution=merge-duplicates,return=representation"}
    try:
        response = requests.post(url, headers=headers, json=payload, params={"on_conflict": on_conflict})
        return response.status_code in (200, 201)
    except Exception as e:
        print(f"Error upserting {table_name}: {e}")
        return False

def _fetch_bulk_users(query_params: dict) -> List[Dict[str, Any]]:
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    
    select_fields = (
        "*, "
        "skills:user_skills(*), "
        "experiences:experiences(*), "
        "quiz_attempts:quiz_attempts(*), "
        "education:education(*)"
    )
    
    params = {**query_params, "select": select_fields}
    url = f"{SUPABASE_URL}/rest/v1/users"
    
    try:
        response = requests.get(url, headers=HEADERS, params=params)
        if response.status_code == 200:
            return response.json()
    except Exception as e:
        print(f"Bulk Fetch Exception: {e}")
    return []

def fetch_already_swiped_ids(actor_id: str) -> List[str]:
    rows = _fetch_table_data("swipe_actions", {"actor_id": f"eq.{actor_id}"})
    return [row['target_id'] for row in rows]

def fetch_recommendations(
    current_user_id: str,
    lat: float = None,
    lng: float = None,
    exclude_ids: List[str] = None,
    filter_type: str = "Meet",
    preferred_roles: List[str] = None,
    max_dist: float = 100.0
) -> List[Dict[str, Any]]:
    """
    Returns top items for the given filter. Excludes already swiped profiles.
    """
    print(f"--- MATCHING ENGINE: {filter_type} mode for {current_user_id} ---")
    if not SUPABASE_URL: return []

    # 1. Fetch current user context
    current_res = _fetch_bulk_users({"id": f"eq.{current_user_id}"})
    if not current_res: return []
    
    current_user = current_res[0]
    current_vector = generate_feature_vector(current_user)
    current_lat = lat or current_user.get('latitude')
    current_lng = lng or current_user.get('longitude')

    # 2. Base Query
    query_params = {"id": f"neq.{current_user_id}", "deleted_at": "is.null"}
    
    if filter_type == "Newbies":
        seven_days_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()
        query_params["created_at"] = f"gte.{seven_days_ago}"
        query_params["order"] = "created_at.desc"
    elif filter_type == "Waves":
        # People who liked current user
        likers_res = _fetch_table_data("swipe_actions", {"target_id": f"eq.{current_user_id}", "action": "eq.like"})
        liker_ids = [r['actor_id'] for r in likers_res]
        if not liker_ids: return []
        query_params["id"] = f"in.({','.join(liker_ids)})"
    elif filter_type == "Views":
        # People who viewed current user's profile
        views_res = _fetch_table_data("profile_views", {"target_id": f"eq.{current_user_id}"})
        viewer_ids = [r['viewer_id'] for r in views_res]
        if not viewer_ids: return []
        query_params["id"] = f"in.({','.join(viewer_ids)})"

    # 3. Apply Preferences (Role filtering)
    if preferred_roles and len(preferred_roles) > 0:
        roles_filter = f"in.({','.join(preferred_roles)})"
        query_params["role"] = roles_filter

    # 4. Fetch Candidates
    candidates = _fetch_bulk_users(query_params)
    
    # Exclude already swiped
    excluded = set(exclude_ids or [])
    candidates = [u for u in candidates if u.get('id') not in excluded]

    # 5. Scoring and Formatting
    scored_users = []
    for other in candidates:
        other_vector = generate_feature_vector(other)
        sim_score = calculate_similarity(current_vector, other_vector)
        
        # Distance
        dist_km = haversine(current_lat, current_lng, other.get('latitude'), other.get('longitude'))
        
        # Filter by distance if preferred
        if dist_km is not None and dist_km > max_dist and filter_type == "Meet":
            continue

        # Location boost (only for Meet mode)
        dist_boost = 0.15 if (dist_km and dist_km < 25) else (0.05 if (dist_km and dist_km < 100) else 0)
        final_score = sim_score + dist_boost
        
        # Threshold for Meet
        if filter_type == "Meet" and final_score < SIMILARITY_THRESHOLD:
            continue

        # Enrichment
        skills_raw = other.get('skills', [])
        skills_formatted = [{"name": s.get('skill_name', ''), "is_verified": bool(s.get('is_verified', False))} for s in skills_raw if s.get('skill_name')]
        
        education = other.get('education', [])
        degree_str = other.get('role', 'Collaborator')
        if education:
            d = education[0].get('degree') or ''
            f = education[0].get('field_of_study') or ''
            degree_str = f"{d} — {f}".strip(' —') or degree_str

        # Experiences
        exps = other.get('experiences', [])
        exp_summary = "Member of CollabBot"
        if exps:
            latest = exps[0]
            exp_summary = f"{latest.get('title', '')} at {latest.get('organization', '')}"

        full_name = other.get('full_name') or 'User'

        scored_users.append({
            "user_id": other.get('id'),
            "name": full_name,
            "title": other.get('role', 'Collaborator'),
            "description": exp_summary,
            "degree": degree_str,
            "skills": skills_formatted[:6],
            "distance": f"{round(dist_km, 1)} km" if dist_km is not None else "Location Hidden",
            "initials": ''.join([n[0] for n in full_name.split()[:2]]).upper() if full_name else 'U',
            "reputation": other.get('reputation', 0),
            "match_score": round(final_score * 100),
            "match_score_raw": final_score
        })

    # Final Sort
    if filter_type == "Meet":
        scored_users.sort(key=lambda x: x['match_score_raw'], reverse=True)
    
    return scored_users[:20]

def record_swipe(actor_id: str, target_id: str, action: str) -> tuple:
    if not SUPABASE_URL: return False, False

    try:
        # 1. Record Swipe Action
        payload = {"actor_id": actor_id, "target_id": target_id, "action": action}
        success = _upsert_table_data("swipe_actions", payload, "actor_id,target_id")
        
        if not success: return False, False

        is_match = False
        if action == "like":
            # 2. Check for reciprocal like
            reciprocal = _fetch_table_data("swipe_actions", {
                "actor_id": f"eq.{target_id}",
                "target_id": f"eq.{actor_id}",
                "action": "eq.like"
            })
            is_match = len(reciprocal) > 0

            if is_match:
                _create_match_and_chat(actor_id, target_id)

        return True, is_match
    except Exception as e:
        print(f"Error in record_swipe: {e}")
        return False, False

def _create_match_and_chat(u1: str, u2: str):
    """Creates records in matches, chats, and chat_participants tables."""
    # 1. Matches Record
    _upsert_table_data("matches", {"user_id": u1, "matched_user_id": u2}, "user_id,matched_user_id")
    
    # 2. Create Chat Room
    chat_url = f"{SUPABASE_URL}/rest/v1/chats"
    chat_res = requests.post(chat_url, headers=HEADERS, json={})
    if chat_res.status_code in (200, 201):
        chat_id = chat_res.json()[0]['id']
        
        # 3. Add Participants
        part_url = f"{SUPABASE_URL}/rest/v1/chat_participants"
        requests.post(part_url, headers=HEADERS, json=[
            {"chat_id": chat_id, "user_id": u1},
            {"chat_id": chat_id, "user_id": u2}
        ])
        print(f"Chat created for match: {chat_id}")
