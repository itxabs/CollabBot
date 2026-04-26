import sys
import os
sys.path.append(os.path.abspath('d:/FYP/collab_bot/backend'))
from matching_service import fetch_recommendations, _fetch_table_data, _fetch_user_full_profile
from similarity_calculator import generate_feature_vector, cosine_similarity

all_users = _fetch_table_data('users')
print(f"Total Users: {len(all_users)}")

for u in all_users:
    uid = u.get("id")
    prof = _fetch_user_full_profile(uid)
    if prof:
        vec = generate_feature_vector(prof)
        print(f"User {u.get('name')} ({uid}) Vector: {vec}")

        # Try fetching recommendations for this user
        recs = fetch_recommendations(uid)
        print(f"  -> Recommended: {len(recs)} users")
