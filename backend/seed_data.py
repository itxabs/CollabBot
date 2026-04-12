import os
import requests
from dotenv import load_dotenv
import uuid

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def seed_users():
    if not SUPABASE_URL:
        print("Error: SUPABASE_URL not found in .env")
        return

    # Sample users to seed
    users = [
        {"id": str(uuid.uuid4()), "full_name": "Ali Hassan", "role": "Senior", "email": "ali.h@example.com", "reputation": 85},
        {"id": str(uuid.uuid4()), "full_name": "Fatima Ahmed", "role": "Junior", "email": "fatima.a@example.com", "reputation": 10},
        {"id": str(uuid.uuid4()), "full_name": "Zaid Khan", "role": "Alumni", "email": "zaid.k@example.com", "reputation": 150},
        {"id": str(uuid.uuid4()), "full_name": "Sana Malik", "role": "Senior", "email": "sana.m@example.com", "reputation": 45},
    ]

    for user in users:
        # 1. Insert User
        res = requests.post(f"{SUPABASE_URL}/rest/v1/users", headers=HEADERS, json=user)
        if res.status_code not in (200, 201):
            print(f"Failed to insert user {user['full_name']}: {res.text}")
            continue
        
        user_id = user['id']
        print(f"Inserted User: {user['full_name']}")

        # 2. Add Skills
        skills = []
        if user['role'] == "Senior":
            skills = [
                {"user_id": user_id, "skill_name": "Flutter", "skill_level_id": 3, "is_verified": True},
                {"user_id": user_id, "skill_name": "Dart", "skill_level_id": 3, "is_verified": True},
                {"user_id": user_id, "skill_name": "Firebase", "skill_level_id": 2, "is_verified": False}
            ]
        elif user['role'] == "Junior":
            skills = [
                {"user_id": user_id, "skill_name": "Flutter", "skill_level_id": 1, "is_verified": False},
                {"user_id": user_id, "skill_name": "Python", "skill_level_id": 1, "is_verified": False}
            ]
        elif user['role'] == "Alumni":
            skills = [
                {"user_id": user_id, "skill_name": "Machine Learning", "skill_level_id": 3, "is_verified": True},
                {"user_id": user_id, "skill_name": "Python", "skill_level_id": 3, "is_verified": True},
                {"user_id": user_id, "skill_name": "Cloud Computing", "skill_level_id": 2, "is_verified": True}
            ]

        if skills:
            requests.post(f"{SUPABASE_URL}/rest/v1/user_skills", headers=HEADERS, json=skills)

        # 3. Add Experience
        if user['role'] != "Junior":
            exp = {
                "user_id": user_id,
                "organization": "Tech Solutions Inc" if user['role'] == "Senior" else "Global Systems",
                "title": "Lead Developer" if user['role'] == "Senior" else "Software Architect",
                "description": "Working on large scale mobile and web applications using Flutter and Python.",
                "start_date": "2021-01-01"
            }
            requests.post(f"{SUPABASE_URL}/rest/v1/experiences", headers=HEADERS, json=exp)

    print("Seeding completed!")

if __name__ == "__main__":
    seed_users()
