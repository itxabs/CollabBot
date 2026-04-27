"""
LinkedIn Profile Data Extraction Service

A lightweight utility for extracting skills and experience data from:
1. HTML content (preferred)
2. Image screenshots (fallback using OCR)

Returns structured JSON with skills and experience information.

⚠️ IMPORTANT:
- This uses heuristic parsing (not 100% accurate)
- Must be used with user confirmation step in UI
- Do NOT rely as guaranteed extraction system
- LinkedIn HTML structure may change anytime
"""

from bs4 import BeautifulSoup
import re
from typing import Dict, List, Any
from PIL import Image
import pytesseract
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============================================================================
# 1. HTML PARSER FUNCTION
# ============================================================================

def extract_from_html(html: str) -> Dict[str, Any]:
    """
    Parse LinkedIn HTML and extract skills and experience.
    
    Args:
        html (str): HTML content from LinkedIn profile
        
    Returns:
        dict: Contains 'skills' list and 'experience' list with role, company, duration
    """
    try:
        soup = BeautifulSoup(html, "html.parser")
        
        skills = []
        experience = []
        
        logger.info("Starting HTML extraction")
        
        # 🔹 METHOD 1: Extract skills from skill-labeled sections
        skill_keywords = ["skills", "expertise", "proficiency", "competency", "technical"]
        skill_section_text = ""
        
        # Look for skill section headers or containers
        for tag in soup.find_all(['h2', 'h3', 'div', 'section']):
            tag_text = tag.get_text(strip=True).lower()
            if any(keyword in tag_text for keyword in skill_keywords):
                logger.info(f"Found skill section: {tag_text[:50]}")
                # Extract content after the skill header
                skill_section_text += tag.get_text() + " "
        
        # 🔹 METHOD 2: Extract from common skill elements
        # Look for divs/spans with skill-like classes or data attributes
        for element in soup.find_all(['div', 'span', 'li', 'a']):
            element_class = element.get('class', [])
            element_id = element.get('id', '')
            
            # Check if element looks like it contains a skill
            if any('skill' in str(c).lower() for c in element_class) or 'skill' in element_id.lower():
                skill_text = element.get_text(strip=True)
                if skill_text and 3 <= len(skill_text) <= 50:
                    skills.append(skill_text)
                    logger.info(f"Found skill from class: {skill_text}")
        
        # 🔹 METHOD 3: Smart keyword extraction from all text
        # Extract all text and look for potential skills
        all_text = soup.get_text(separator='\n')
        lines = all_text.split('\n')
        
        # Common technical skills to look for
        common_skills = [
            'python', 'java', 'javascript', 'typescript', 'c++', 'c#', 'php', 'ruby', 'go', 'rust',
            'flutter', 'react', 'vue', 'angular', 'django', 'fastapi', 'nodejs', 'node.js',
            'html', 'css', 'sql', 'mysql', 'postgresql', 'mongodb', 'firebase', 'aws', 'azure', 'gcp',
            'git', 'docker', 'kubernetes', 'jenkins', 'ci/cd', 'linux', 'windows',
            'machine learning', 'deep learning', 'ai', 'nlp', 'computer vision',
            'rest api', 'graphql', 'websocket', 'oauth', 'jwt',
            'ui design', 'ux design', 'figma', 'adobe xd', 'photoshop', 'illustrator',
            'agile', 'scrum', 'kanban', 'jira', 'asana',
            'leadership', 'communication', 'teamwork', 'project management',
            'excel', 'powerpoint', 'word', 'google workspace', 'slack', 'confluence'
        ]
        
        for line in lines:
            line_clean = line.strip()
            if line_clean and 3 <= len(line_clean) <= 50:
                # Check if line matches any common skill
                for skill in common_skills:
                    if skill.lower() in line_clean.lower():
                        skills.append(line_clean)
                        logger.info(f"Found skill from keyword match: {line_clean}")
                        break
        
        # 🔹 METHOD 4: Extract from content around "skill" text
        for tag in soup.find_all(text=True):
            tag_lower = tag.lower().strip()
            if 'skill' in tag_lower and len(tag_lower) < 100:
                parent = tag.find_parent()
                if parent:
                    parent_text = parent.get_text(strip=True)
                    # Extract adjacent text that might be skills
                    if parent_text and len(parent_text) > 5 and len(parent_text) < 100:
                        skills.append(parent_text)
                        logger.info(f"Found skill near 'skill' keyword: {parent_text[:50]}")
        
        # Clean and deduplicate skills
        skills = list(dict.fromkeys([s for s in skills if s and len(s) < 50]))
        # Remove entries that look like headers or UI elements
        skills = [
            s for s in skills 
            if len(s) > 2 and not any(x in s.lower() for x in ['skills', 'expertise', 'your', 'their', 'this'])
        ]
        
        logger.info(f"Extracted {len(skills)} skills: {skills[:5] if skills else 'none'}")
        
        # 🔹 Extract experience (improved heuristic approach)
        text = soup.get_text()
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        
        logger.info(f"Processing {len(lines)} lines for experience extraction")
        
        for i, line in enumerate(lines):
            # Pattern 1: Look for "Role at Company"
            if " at " in line.lower():
                role_company = line.strip()
                duration = lines[i + 1].strip() if i + 1 < len(lines) else ""
                
                # Filter out false positives (check length and validity)
                if 5 < len(role_company) < 150 and not any(word in role_company.lower() for word in ['at the', 'that', 'what', 'which']):
                    experience.append({
                        "role_company": role_company,
                        "duration": duration
                    })
                    logger.info(f"Found experience (Pattern 1): {role_company}")
            
            # Pattern 2: Company name followed by duration dates
            month_list = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            has_month = any(month in line for month in month_list)
            has_date_indicator = "-" in line or "Present" in line or "•" in line
            
            if has_month and has_date_indicator and len(line) < 50:
                if i > 0:
                    role_company = lines[i - 1].strip()
                    if len(role_company) > 3:
                        experience.append({
                            "role_company": role_company,
                            "duration": line.strip()
                        })
                        logger.info(f"Found experience (Pattern 2): {role_company} | {line.strip()}")
            
            # Pattern 3: Look for job title patterns
            job_keywords = ['engineer', 'developer', 'designer', 'manager', 'analyst', 'consultant', 
                           'lead', 'director', 'founder', 'ceo', 'associate', 'specialist']
            if any(keyword in line.lower() for keyword in job_keywords) and len(line) < 100:
                duration = lines[i + 1].strip() if i + 1 < len(lines) else ""
                if duration and (has_month or "-" in duration):
                    experience.append({
                        "role_company": line.strip(),
                        "duration": duration
                    })
                    logger.info(f"Found experience (Pattern 3): {line.strip()}")
        
        # Remove duplicates while preserving order
        seen = set()
        unique_experience = []
        for exp in experience:
            key = exp.get("role_company", "")
            if key not in seen and len(key) > 3:
                seen.add(key)
                unique_experience.append(exp)
        
        logger.info(f"Extracted {len(unique_experience)} unique experiences")
        logger.info(f"Final extraction: {len(skills)} skills, {len(unique_experience)} experiences")
        
        return {
            "skills": skills[:20],  # Limit to top 20
            "experience": unique_experience[:10],  # Limit to top 10
            "extraction_method": "html",
            "success": True,
            "debug_info": {
                "total_lines_processed": len(lines),
                "skills_found": len(skills),
                "experiences_found": len(unique_experience)
            }
        }
    
    except Exception as e:
        logger.error(f"Error extracting from HTML: {str(e)}")
        return {
            "skills": [],
            "experience": [],
            "error": str(e),
            "extraction_method": "html",
            "success": False
        }


# ============================================================================
# 2. OCR IMAGE PARSER
# ============================================================================

def extract_from_image(image_path: str) -> Dict[str, Any]:
    """
    Extract text from screenshot using OCR and parse it.
    
    Args:
        image_path (str): Path to image file (PNG, JPG, etc.)
        
    Returns:
        dict: Contains 'skills' list and 'experience' list
    """
    try:
        if not os.path.exists(image_path):
            return {
                "error": f"Image file not found: {image_path}",
                "extraction_method": "image",
                "success": False,
                "skills": [],
                "experience": []
            }
        
        logger.info(f"Extracting text from image: {image_path}")
        
        # Open image and extract text using OCR
        image = Image.open(image_path)
        text = pytesseract.image_to_string(image)
        
        if not text.strip():
            return {
                "error": "No text could be extracted from image (OCR failed)",
                "extraction_method": "image",
                "success": False,
                "skills": [],
                "experience": []
            }
        
        logger.info(f"Extracted {len(text)} characters from image")
        
        # Reuse HTML parser logic on plain text
        # Wrap text in basic HTML structure for parser
        html_content = f"<html><body>{text}</body></html>"
        result = extract_from_html(html_content)
        result["extraction_method"] = "image_ocr"
        
        return result
    
    except FileNotFoundError:
        return {
            "error": f"Image file not found: {image_path}",
            "extraction_method": "image",
            "success": False,
            "skills": [],
            "experience": []
        }
    except Exception as e:
        logger.error(f"Error extracting from image: {str(e)}")
        return {
            "error": str(e),
            "extraction_method": "image",
            "success": False,
            "skills": [],
            "experience": []
        }


# ============================================================================
# 3. UNIFIED EXTRACTION FUNCTION
# ============================================================================

def extract_linkedin_data(
    html: str = None,
    image_path: str = None
) -> Dict[str, Any]:
    """
    Extract LinkedIn profile data from HTML or image.
    
    Args:
        html (str, optional): HTML content from LinkedIn
        image_path (str, optional): Path to LinkedIn screenshot
        
    Returns:
        dict: Structured extraction result with skills and experience
    """
    if html:
        return extract_from_html(html)
    elif image_path:
        return extract_from_image(image_path)
    else:
        return {
            "error": "Either 'html' or 'image_path' must be provided",
            "success": False,
            "skills": [],
            "experience": []
        }


# ============================================================================
# 4. VALIDATION FUNCTIONS
# ============================================================================

def validate_extraction(data: Dict[str, Any]) -> bool:
    """
    Validate extraction result format.
    
    Args:
        data (dict): Extraction result
        
    Returns:
        bool: True if valid format
    """
    required_keys = {"skills", "experience"}
    return all(key in data for key in required_keys)


def clean_extracted_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Clean and normalize extracted data.
    
    Args:
        data (dict): Raw extraction result
        
    Returns:
        dict: Cleaned data with normalized strings
    """
    cleaned = {
        "skills": [s.strip() for s in data.get("skills", []) if s.strip()],
        "experience": [
            {
                "role_company": exp.get("role_company", "").strip(),
                "duration": exp.get("duration", "").strip()
            }
            for exp in data.get("experience", [])
            if exp.get("role_company", "").strip()
        ]
    }
    
    return cleaned


# ============================================================================
# 5. EXAMPLE USAGE
# ============================================================================

if __name__ == "__main__":
    # Example HTML extraction
    sample_html = """
    <html>
    <body>
        <div class="skill">Python</div>
        <div class="skill">FastAPI</div>
        <div>Software Engineer at Tech Corp</div>
        <div>Jan 2021 - Present</div>
    </body>
    </html>
    """
    
    result = extract_from_html(sample_html)
    print("HTML Extraction Result:")
    print(result)
