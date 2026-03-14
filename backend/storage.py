import os
from fastapi import UploadFile

BASE_PATH = "storage/resumes"

def save_resume_file(user_id: str, resume_id: str, file: UploadFile):
    """
    Saves the uploaded resume file to the local storage.
    Path: storage/resumes/{user_id}/{resume_id}.{ext}
    """
    # Create user-specific directory
    user_dir = os.path.join(BASE_PATH, user_id)
    os.makedirs(user_dir, exist_ok=True)

    # Determine file extension
    filename = file.filename or "resume"
    ext = filename.split(".")[-1] if "." in filename else "pdf"
    
    # Construct full file path
    file_path = os.path.join(user_dir, f"{resume_id}.{ext}")

    # Write file bytes to disk
    with open(file_path, "wb") as f:
        f.write(file.file.read())
        
    # Reset file cursor for potential future use (though we consumed it)
    file.file.seek(0)

    return file_path
