"""Settings and configuration for the application."""
import os
from dotenv import load_dotenv

load_dotenv()

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://cpuhivcyhvqayzgdvdaw.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk")

# Groq API Configuration
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# OpenAI Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Application Settings
DEBUG = os.getenv("DEBUG", "false").lower() == "true"
