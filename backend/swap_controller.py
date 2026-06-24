from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import requests
from datetime import datetime, timedelta
from matching_service import (
    fetch_recommendations, record_swipe, fetch_already_swiped_ids, 
    record_view, SUPABASE_URL, SUPABASE_KEY, HEADERS, _fetch_table_data
)

router = APIRouter(prefix="/swap", tags=["Swap"])


class SwipeRequest(BaseModel):
    user_id: str
    target_user_id: str
    action: str  # "like", "reject", or "restore"

class ViewRequest(BaseModel):
    viewer_id: str
    target_id: str

@router.get("/recommendations")
async def get_recommendations(
    user_id: str,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    filter_type: Optional[str] = "Meet",
    roles: Optional[List[str]] = Query(None),
    max_dist: Optional[float] = 100.0
) -> List[Dict[str, Any]]:
    """
    Returns recommended users based on filters, distance, and preferred roles.
    """
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required")

    try:
        exclude_ids = fetch_already_swiped_ids(user_id)
        
        recommendations = fetch_recommendations(
            user_id,
            lat=lat,
            lng=lng,
            exclude_ids=exclude_ids,
            filter_type=filter_type,
            preferred_roles=roles,
            max_dist=max_dist
        )
        print(f"DEBUG: Returning {len(recommendations)} recommendations for user {user_id}")
        return recommendations

    except Exception as e:
        print(f"Error in get_recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/counts")
async def get_swap_counts(user_id: str):
    """
    Returns real counts for Waves (who liked you), Views (who viewed you), and Newbies.
    """
    try:
        from matching_service import fetch_already_swiped_ids, _fetch_table_data, fetch_recommendations
        exclude_ids = fetch_already_swiped_ids(user_id)
        
        # Waves: People who liked you but you haven't swiped yet
        likers_res = _fetch_table_data("swipe_actions", {"target_id": f"eq.{user_id}", "action": "eq.like"})
        waves_count = len([r for r in likers_res if r['actor_id'] not in exclude_ids])

        # Views: People who viewed your profile
        views_res = _fetch_table_data("profile_views", {"target_id": f"eq.{user_id}"})
        views_count = len(views_res)

        # Newbies: People who joined recently
        newbies_res = _fetch_table_data("users", {"deleted_at": "is.null", "id": f"neq.{user_id}", "created_at": f"gte.{(datetime.utcnow() - timedelta(days=7)).isoformat()}"})
        newbies_count = len([u for u in newbies_res if u['id'] not in exclude_ids])
        
        # Meet: Count of available recommendations (Total users - swiped)
        all_users = _fetch_table_data("users", {"deleted_at": "is.null", "id": f"neq.{user_id}"})
        meet_count = len([u for u in all_users if u['id'] not in exclude_ids])
        
        return {
            "Meet": meet_count, 
            "Waves": waves_count,
            "Views": views_count,
            "Newbies": newbies_count
        }
    except Exception as e:
        print(f"Error in get_counts: {e}")
        return {"Meet": 0, "Waves": 0, "Views": 0, "Newbies": 0}

@router.post("/view")
async def register_view(request: ViewRequest):
    success = record_view(request.viewer_id, request.target_id)
    if success:
        return {"status": "success"}
    raise HTTPException(status_code=500, detail="Failed to record view")

@router.post("/swipe")
async def swipe_user(request: SwipeRequest):
    if request.action not in ("like", "reject", "restore"):
        raise HTTPException(status_code=400, detail="action must be 'like', 'reject', or 'restore'")

    success, is_match = record_swipe(request.user_id, request.target_user_id, request.action)

    if success:
        return {
            "status": "success",
            "action": request.action,
            "message": "It's a match! 🎉" if is_match else "Action recorded.",
            "is_match": is_match
        }
    else:
        raise HTTPException(status_code=500, detail="Failed to record action")

@router.get("/matches")
async def get_matches(user_id: str):
    """
    Returns a list of users that the current user has matched with (mutual likes).
    """
    try:
        from matching_service import _fetch_table_data, _fetch_bulk_users
        
        # 1. Fetch matches where user_id is involved
        # Assuming matches table stores successful matches
        matches_res = _fetch_table_data("matches", {"user_id": f"eq.{user_id}"})
        matched_user_ids = [m['matched_user_id'] for m in matches_res]
        
        # Also check where user_id is the 'matched_user_id'
        matches_res_rev = _fetch_table_data("matches", {"matched_user_id": f"eq.{user_id}"})
        matched_user_ids.extend([m['user_id'] for m in matches_res_rev])
        
        if not matched_user_ids:
            return []
            
        # 2. Fetch user details for these IDs
        matched_users = _fetch_bulk_users({"id": f"in.({','.join(matched_user_ids)})"})
        
        return [{
            "user_id": u['id'],
            "name": u.get('full_name', 'User'),
            "role": u.get('role', 'Collaborator'),
            "profile_picture_url": u.get('profile_picture_url'),
            "initials": ''.join([n[0] for n in u.get('full_name', 'U').split()[:2]]).upper()
        } for u in matched_users]
    except Exception as e:
        print(f"Error in get_matches: {e}")
        return []

@router.post("/reset")
async def reset_swipes(user_id: str):
    """
    Deletes all swipe actions for the given user. 
    Useful for testing with limited users.
    """
    try:
        url = f"{SUPABASE_URL}/rest/v1/swipe_actions"
        params = {"actor_id": f"eq.{user_id}"}
        response = requests.delete(url, headers=HEADERS, params=params)
        return {"status": "success", "message": "Swipes reset."}
    except Exception as e:
        print(f"Error in reset_swipes: {e}")
        raise HTTPException(status_code=500, detail=str(e))



