from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from matching_service import fetch_recommendations, record_like

router = APIRouter(prefix="/swap", tags=["Swap"])

class LikeRequest(BaseModel):
    user_id: str
    liked_user_id: str

@router.get("/recommendations")
async def get_recommendations(user_id: str) -> List[Dict[str, Any]]:
    """
    Returns the top 10 most similar users based on AI Cosine Similarity.
    """
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required")
        
    try:
        recommendations = fetch_recommendations(user_id)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/like")
async def like_user(request: LikeRequest):
    """
    Records a like between two users. If mutual, saves to the matches table.
    """
    success = record_like(request.user_id, request.liked_user_id)
    if success:
        return {"status": "success", "message": "Like recorded successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to record like or match")
