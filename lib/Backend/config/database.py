"""Database client initialization."""
from supabase import create_client, Client
from config.settings import SUPABASE_URL, SUPABASE_KEY

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Alias for backward compatibility
db = supabase
