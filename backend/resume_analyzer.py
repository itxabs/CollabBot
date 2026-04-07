import pdfplumber
import docx
import re
import os

def extract_text_from_pdf(file_path):
    """Extracts text from a PDF file."""
    text = ""
    try:
        with pdfplumber.open(file_path) as pdf:
            for page in pdf.pages:
                extracted = page.extract_text()
                if extracted:
                    text += extracted + "\n"
    except Exception as e:
        print(f"Error extracting PDF text: {e}")
    return text

def extract_text_from_docx(file_path):
    """Extracts text from a DOCX file."""
    try:
        doc = docx.Document(file_path)
        return "\n".join(p.text for p in doc.paragraphs)
    except Exception as e:
        print(f"Error extracting DOCX text: {e}")
        return ""

def analyze_resume(text: str):
    """
    Analyzes the resume text based on specific ATS rules.
    Returns a tuple (score, recommendations).
    """
    score = 0
    recommendations = []

    # 1. Section Presence (Max 80 points)
    sections = {
        "experience": 25,
        "skills": 20,
        "education": 15,
        "projects": 10,
        "certifications": 10,
    }

    text_lower = text.lower()

    for section, points in sections.items():
        if section in text_lower:
            score += points
        else:
            recommendations.append(f"Add a clear {section.title()} section.")

    # Tokenization for word count
    words = re.findall(r"\b\w+\b", text)
    word_count = len(words)

    # 2. Length Rules
    if word_count < 150:
        score -= 10
        recommendations.append("Resume is too short. Aim for 400–600 words.")
    elif word_count > 800:
        score -= 10
        recommendations.append("Resume is too long. Keep it under 2 pages.")

    # 3. Keyword Matching (Max 20 points)
    keywords = [
        "teamwork",
        "communication",
        "leadership",
        "python",
        "machine learning",
        "project management",
    ]

    # Calculate keyword hits (+4 points per keyword found)
    keyword_hits = sum(1 for kw in keywords if kw in text_lower)
    score += min(keyword_hits * 4, 20)
    
    # 4. Formatting Penalties
    # Check for 4-digit year (simple regex)
    if not re.search(r"\b\d{4}\b", text):
        score -= 5
        recommendations.append("Add years to your experience or education.")

    # Check for line breaks
    if text.count("\n") < 10:
        score -= 5
        recommendations.append("Improve formatting with proper spacing.")

    # Final Score Clamping
    score = max(0, min(100, score))

    return score, recommendations
