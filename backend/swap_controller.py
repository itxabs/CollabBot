from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from matching_service import fetch_recommendations, record_swipe, fetch_already_swiped_ids, record_view

router = APIRouter(prefix="/swap", tags=["Swap"])

class SwipeRequest(BaseModel):
    user_id: str
    target_user_id: str
    action: str  # "like" or "reject"

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
        newbies = fetch_recommendations(user_id, filter_type="Newbies")
        newbies_count = len(newbies)
        
        return {
            "Meet": 15, 
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
    if request.action not in ("like", "reject"):
        raise HTTPException(status_code=400, detail="action must be 'like' or 'reject'")

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
