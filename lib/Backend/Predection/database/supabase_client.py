from supabase import create_client
from config.settings import SUPABASE_URL, SUPABASE_KEY

class SupabaseClient:
    def __init__(self):
        self.client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    def get_user_messages(self, user_id: str, limit: int = 100):
        return (
            self.client.from_("messages")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_bot", False)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
    
    def update_prediction(self, message_id: str, prediction: str, confidence: float):
        return (
            self.client.from_("messages")
            .update({
                "mentality_prediction": prediction,
                "prediction_confidence": confidence
            })
            .eq("id", message_id)
            .execute()
        )

db = SupabaseClient()
