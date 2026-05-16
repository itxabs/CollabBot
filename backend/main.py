from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uuid
import os
import logging
from dotenv import load_dotenv

# Load environment variables from ROOT directory
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'), override=True)

from pydantic import BaseModel
from resume_analyzer import analyze_resume, extract_text_from_pdf, extract_text_from_docx
from storage import save_resume_file
from swap_controller import router as swap_router
from linkedin_routes import router as linkedin_router
from ai_service import get_ai_suggestion, sync_answer_embedding

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AiSuggestionRequest(BaseModel):
    message: str

class VectorizeRequest(BaseModel):
    answer_id: str
    content: str

app = FastAPI()

# Add CORS middleware if needed by the Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(swap_router)
app.include_router(linkedin_router)

@app.post("/analyze-resume")
async def analyze_resume_api(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):
    """
    Endpoint to analyze a resume (PDF or DOCX).
    Saves the file, extracts text, performs ATS analysis, and returns the score.
    """
    # 1. Validate File Validation
    filename = file.filename or ""
    if not filename.lower().endswith((".pdf", ".docx")):
        raise HTTPException(status_code=400, detail="Only PDF and DOCX allowed")

    # 2. Storage Call
    resume_id = str(uuid.uuid4())
    try:
        file_path = save_resume_file(user_id, resume_id, file)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save file: {str(e)}")

    # 3. Text Extraction
    text = ""
    if filename.lower().endswith(".pdf"):
        text = extract_text_from_pdf(file_path)
    elif filename.lower().endswith(".docx"):
        text = extract_text_from_docx(file_path)
    
    if not text.strip():
         return {
            "score": 0,
            "recommendations": ["Could not extract text from document. Ensure it's not an empty or image-only file."]
        }

    # 4. ATS Analysis Call
    score, recommendations = analyze_resume(text)

    # 5. Return Response
    return {
        "score": score,
        "recommendations": recommendations
    }


@app.get("/health")
async def health_check():
    """
    Comprehensive health check for all services.
    Tests: matching_service, resume_analyzer, and linkedin_extractor
    """
    health_status = {
        "status": "operational",
        "services": {}
    }
    
    # Test resume_analyzer
    try:
        test_text = "Experience: Software Engineer at Tech Corp. Skills: Python"
        score, recommendations = analyze_resume(test_text)
        health_status["services"]["resume_analyzer"] = {
            "status": "healthy",
            "test_score": score,
            "recommendations_count": len(recommendations)
        }
        logger.info("✓ Resume Analyzer: Healthy")
    except Exception as e:
        health_status["services"]["resume_analyzer"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        logger.error(f"✗ Resume Analyzer: {str(e)}")
    
    # Test linkedin_extractor
    try:
        from linkedin_extractor import extract_from_html
        test_html = "<html><body><div class='skill'>Python</div></body></html>"
        result = extract_from_html(test_html)
        health_status["services"]["linkedin_extractor"] = {
            "status": "healthy",
            "test_skills_found": len(result.get("skills", [])),
            "extraction_method": result.get("extraction_method")
        }
        logger.info("✓ LinkedIn Extractor: Healthy")
    except Exception as e:
        health_status["services"]["linkedin_extractor"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        logger.error(f"✗ LinkedIn Extractor: {str(e)}")
    
    # Test matching_service (basic import check)
    try:
        import matching_service
        health_status["services"]["matching_service"] = {
            "status": "healthy",
            "message": "Module loaded successfully"
        }
        logger.info("✓ Matching Service: Healthy")
    except Exception as e:
        health_status["services"]["matching_service"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        logger.error(f"✗ Matching Service: {str(e)}")
    
    return health_status


@app.post("/debug/extract-html")
async def debug_extract_html(data: dict):
    """
    Debug endpoint to see detailed extraction output.
    Shows what's being extracted and how.
    """
    from linkedin_extractor import extract_from_html
    from bs4 import BeautifulSoup
    
    html = data.get("html", "")
    
    if not html:
        raise HTTPException(status_code=400, detail="HTML is required")
    
    # Get extraction result
    result = extract_from_html(html)
    
    # Also provide raw HTML analysis
    soup = BeautifulSoup(html, "html.parser")
    
    debug_info = {
        "extraction_result": result,
        "raw_analysis": {
            "total_text_length": len(soup.get_text()),
            "total_lines": len(soup.get_text().split('\n')),
            "total_divs": len(soup.find_all('div')),
            "total_spans": len(soup.find_all('span')),
            "all_text_nodes": [
                t.strip()[:50] for t in soup.find_all(text=True) 
                if t.strip() and len(t.strip()) > 3
            ][:20]  # First 20 text nodes
        }
    }
    
    logger.info(f"Debug extraction: {len(result.get('skills', []))} skills, {len(result.get('experience', []))} experiences")
    
    return debug_info


@app.post("/ai/suggest")
async def ai_suggest(request: AiSuggestionRequest):
    """
    Endpoint to get an AI-powered suggested response for a chat message.
    Uses RAG with Gemini and Supabase.
    """
    try:
        reply = get_ai_suggestion(request.message)
        return {"suggestion": reply}
    except Exception as e:
        logger.error(f"AI Suggestion Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ai/vectorize-answer")
async def vectorize_answer(request: VectorizeRequest):
    """
    Endpoint called by Flutter after a new answer is posted.
    Generates and saves the 3072-D embedding for RAG.
    """
    try:
        success = sync_answer_embedding(request.answer_id, request.content)
        return {"success": success}
    except Exception as e:
        logger.error(f"Vectorization Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
