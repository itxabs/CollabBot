import os
import requests
from google import genai
from dotenv import load_dotenv
import traceback

def get_ai_suggestion(message: str) -> str:
    """
    Stateless RAG flow using the LATEST V2 SDK (google-genai).
    """
    try:
        # 1. Force Reload Environment from Root
        env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
        load_dotenv(env_path, override=True)
        
        api_key = os.getenv("GEMINI_API_KEY")
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_KEY")
        
        if not api_key:
            return "AI Service Error: Missing API Key"

        # 2. Initialize V2 Client
        client = genai.Client(api_key=api_key)
        
        # 3. Model Names (Discovered for V2)
        gen_model = "gemini-2.5-flash"
        embed_model = "gemini-embedding-2" 
        
        # 4. Generate Embedding (V2 Syntax)
        embedding = None
        try:
            result = client.models.embed_content(
                model=embed_model,
                contents=message
            )
            # V2 result structure: result.embeddings[0].values
            if result.embeddings:
                embedding = result.embeddings[0].values
        except Exception as e:
            print(f"Embedding Warning ({embed_model}): {e}")
            # Try fallback embedding
            try:
                result = client.models.embed_content(model="models/embedding-001", contents=message)
                if result.embeddings:
                    embedding = result.embeddings[0].values
            except:
                pass

        # 5. Search Context (RAG)
        context = ""
        if embedding:
            rpc_url = f"{supabase_url}/rest/v1/rpc/match_answers"
            headers = {
                "apikey": supabase_key,
                "Authorization": f"Bearer {supabase_key}",
                "Content-Type": "application/json"
            }
            payload = {
                "query_embedding": embedding,
                "match_threshold": 0.1,
                "match_count": 5
            }
            
            try:
                response = requests.post(rpc_url, headers=headers, json=payload, timeout=5)
                if response.status_code == 200:
                    answers = response.json()
                    if answers:
                        print(f"--- RAG SEARCH SUCCESS ---")
                        print(f"Found {len(answers)} relevant answers in your knowledge base.")
                        for i, a in enumerate(answers[:2], 1): # Show first two matches
                            print(f"[{i}] {a.get('content', '')[:100]}...")
                        print(f"--------------------------")
                        context = "\n".join([f"Context: {a.get('content', '')}" for a in answers])
                    else:
                        print("--- RAG SEARCH INFO ---")
                        print("No matches found in your knowledge base. Using general AI knowledge.")
                        print("-----------------------")
            except Exception as e:
                print(f"Supabase Search Warning: {e}")

        # 6. Generate Conversational Response (V2 Syntax)
        # Note: 'system_instruction' in V2 is part of Config
        response = client.models.generate_content(
            model=gen_model,
            contents=f"Available Context:\n{context}\n\nUser Question: {message}\n",
            config={
                "system_instruction": (
                    "You are a professional assistant for a student/developer collaboration platform. "
                    "Provide a concise, helpful reply to the user message. "
                    "STRICT RULE: MAX 3 SENTENCES. Sound natural, professional, and helpful."
                )
            }
        )
        
        return response.text.strip() if response.text else "I'm here to help, but couldn't think of a reply."

    except Exception as e:
        print(f"AI Service Critical Error: {e}")
        # traceback.print_exc()
        return "I'm having a little trouble thinking right now. Please try again in a moment."

def sync_answer_embedding(answer_id: str, content: str) -> bool:
    """
    Generates embedding and updates Supabase for a specific answer.
    """
    try:
        # 1. Reload Environment
        env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
        load_dotenv(env_path, override=True)
        
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        genai_key = os.getenv("GEMINI_API_KEY")
        
        if not genai_key or not url:
            return False

        # 2. Generate Embedding
        client = genai.Client(api_key=genai_key)
        result = client.models.embed_content(
            model="gemini-embedding-2",
            contents=content
        )
        
        if result.embeddings:
            vector = result.embeddings[0].values
            
            # 3. Update Supabase
            update_url = f"{url}/rest/v1/answers?id=eq.{answer_id}"
            headers = {
                "apikey": key,
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                "Prefer": "return=minimal"
            }
            res = requests.patch(update_url, headers=headers, json={"embedding": vector})
            return res.status_code in [200, 204]
            
        return False
    except Exception as e:
        print(f"Sync Answer Error: {e}")
        return False
