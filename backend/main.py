from fastapi import FastAPI, UploadFile, File, Form, HTTPException
import uuid
import os
from resume_analyzer import analyze_resume, extract_text_from_pdf, extract_text_from_docx
from storage import save_resume_file

app = FastAPI()

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
