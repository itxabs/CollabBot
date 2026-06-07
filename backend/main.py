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
import requests
import time

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


@app.post('/agora/token')
async def agora_token(payload: dict):
    """
    Generate a short-lived Agora RTC token for a given chat.
    Expects JSON: { "chat_id": "<chat_id>", "user_id": "<user_id>", "uid": <numeric_uid optional> }

    Validates that `user_id` is a participant in the chat via Supabase REST, then
    builds and returns an Agora token and metadata.
    """
    try:
        AGORA_APP_ID = os.getenv('AGORA_APP_ID')
        AGORA_APP_CERT = os.getenv('AGORA_APP_CERT')
        SUPABASE_URL = os.getenv('SUPABASE_URL')
        SUPABASE_KEY = os.getenv('SUPABASE_KEY')

        if not AGORA_APP_ID or not AGORA_APP_CERT:
            raise HTTPException(status_code=500, detail='Agora credentials not configured')

        chat_id = payload.get('chat_id')
        user_id = payload.get('user_id')
        uid = payload.get('uid', 0)

        if not chat_id or not user_id:
            raise HTTPException(status_code=400, detail='chat_id and user_id are required')

        try:
            uuid.UUID(str(chat_id))
            uuid.UUID(str(user_id))
        except ValueError:
            raise HTTPException(status_code=400, detail='chat_id and user_id must be valid UUID values')

        logger.info(f'Agora token requested for chat_id={chat_id}, user_id={user_id}, uid={uid}')

        # Validate participant via Supabase REST
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise HTTPException(status_code=500, detail='Supabase configuration missing')

        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
        }
        part_url = f"{SUPABASE_URL}/rest/v1/chat_participants"
        params = {'chat_id': f'eq.{chat_id}'}
        resp = requests.get(part_url, headers=headers, params=params)
        if resp.status_code != 200:
            detail = f'Failed to validate chat participants: Supabase returned {resp.status_code} {resp.text[:200]}'
            logger.error(detail)
            raise HTTPException(status_code=502, detail=detail)

        participants = resp.json()
        user_ids = [p.get('user_id') for p in participants]
        if str(user_id) not in [str(x) for x in user_ids]:
            raise HTTPException(status_code=403, detail='User not a participant of the chat')

        # Generate Agora token
        # Try importing token builder from agora-access-token package
        try:
            from agora_token_builder import RtcTokenBuilder
        except Exception as import_error:
            try:
                from agora_access_token import RtcTokenBuilder
            except Exception as fallback_error:
                logger.error(
                    'Agora token builder import failed. '
                    f'agora_token_builder={import_error}; agora_access_token={fallback_error}'
                )
                raise HTTPException(status_code=500, detail='Agora token builder library is not installed on server')

        # role: 1 = publisher, 2 = subscriber in some libs; adapt to builder API
        role = 1
        expire_seconds = 3600  # 1 hour
        current_ts = int(time.time())
        privilege_expired_ts = current_ts + expire_seconds

        try:
            token = RtcTokenBuilder.buildTokenWithUid(
                AGORA_APP_ID,
                AGORA_APP_CERT,
                str(chat_id),
                int(uid),
                role,
                privilege_expired_ts,
            )
        except Exception as e:
            logger.error(f'Agora token build error: {e}')
            raise HTTPException(status_code=500, detail='Failed to build Agora token')

        return {
            'appId': AGORA_APP_ID,
            'channel': str(chat_id),
            'uid': int(uid),
            'token': token,
            'expiresAt': privilege_expired_ts,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f'Agora token endpoint error: {e}')
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
