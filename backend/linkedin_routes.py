"""
FastAPI Integration for LinkedIn Extractor Service

Optional endpoints for the LinkedIn extraction service.
Import this router into main.py to add the endpoints:

    from linkedin_routes import router as linkedin_router
    app.include_router(linkedin_router)

⚠️ This is optional - you can use linkedin_extractor.py as a standalone utility
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
import os
import tempfile
from linkedin_extractor import (
    extract_from_html,
    extract_from_image,
    extract_linkedin_data,
    clean_extracted_data
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/linkedin", tags=["linkedin-extraction"])


class HtmlInput(BaseModel):
    """Request model for HTML extraction"""
    html: str


class ExtractionResponse(BaseModel):
    """Response model for extraction results"""
    skills: list
    experience: list
    extraction_method: str = None
    success: bool = True
    error: str = None


@router.post("/extract/html", response_model=ExtractionResponse)
async def extract_html_endpoint(data: HtmlInput):
    """
    Extract LinkedIn profile data from HTML content.
    
    Args:
        data: Object containing 'html' field with LinkedIn HTML
        
    Returns:
        ExtractionResponse with extracted skills and experience
    """
    if not data.html or not data.html.strip():
        raise HTTPException(status_code=400, detail="HTML content cannot be empty")
    
    result = extract_from_html(data.html)
    cleaned = clean_extracted_data(result)
    
    return {
        **cleaned,
        "extraction_method": result.get("extraction_method"),
        "success": result.get("success", True),
        "error": result.get("error")
    }


@router.post("/extract/image", response_model=ExtractionResponse)
async def extract_image_endpoint(file: UploadFile = File(...)):
    """
    Extract LinkedIn profile data from image screenshot using OCR.
    
    Args:
        file: Image file (PNG, JPG, etc.)
        
    Returns:
        ExtractionResponse with extracted skills and experience
    """
    # Validate file type
    allowed_extensions = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"}
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"
        )
    
    # Save uploaded file temporarily
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, f"linkedin_extract_{file.filename}")
    
    try:
        # Write file to temporary location
        with open(temp_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # Extract data from image
        result = extract_from_image(temp_path)
        cleaned = clean_extracted_data(result)
        
        return {
            **cleaned,
            "extraction_method": result.get("extraction_method"),
            "success": result.get("success", True),
            "error": result.get("error")
        }
    
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")
    
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)


@router.get("/health")
async def linkedin_service_health():
    """Health check endpoint for LinkedIn extraction service"""
    return {
        "service": "linkedin-extractor",
        "status": "operational",
        "endpoints": [
            "/linkedin/extract/html",
            "/linkedin/extract/image"
        ]
    }
