from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from matching_service import fetch_recommendations, record_like

router = APIRouter(prefix="/swap", tags=["Swap"])

class LikeRequest(BaseModel):
    user_id: str
    liked_user_id: str

@router.get("/recommendations")
async def get_recommendations(user_id: str, lat: float = None, lng: float = None) -> List[Dict[str, Any]]:
    """
    Returns the top 10 most similar users based on AI Similarity and Location.
    """
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required")
        
    try:
        recommendations = fetch_recommendations(user_id, lat=lat, lng=lng)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/like")
async def like_user(request: LikeRequest):
    """
    Records a like between two users. If mutual, returns is_match=True.
    """
    success, is_match = record_like(request.user_id, request.liked_user_id)
    if success:
        return {
            "status": "success", 
            "message": "Match pending" if not is_match else "Mutual match found!",
            "is_match": is_match
        }
    else:
        raise HTTPException(status_code=500, detail="Failed to record like or match")
