# SafeSpace 🛡️

SafeSpace is a Flutter-based mobile application focused on **mental health, counseling, and safe community interactions**.  
The app provides users with a supportive platform to connect with counselors, access resources, and engage in anonymous group discussions.  

---

## ✨ Features

- 🔐 **Authentication** – Secure sign-up and sign-in with Supabase
- 🎧 **Entertainment & Relaxation** – Meditation, music, and interactive exercises  
- 🤖 **AI Chatbot** – Intelligent mental health assistant powered by Groq LLM with real-time responses
- 🧠 **Mental State Analysis** – Automatic analysis of user messages to predict mental health states
- 💡 **AI Suggestions** – Personalized wellness recommendations based on dominant mental state
- 👨‍⚕️ **Doctor Recommendations** – Smart matching with mental health professionals based on mental state
- 🎬 **Entertainment Recommendations** – Curated content matching user's emotional needs
- 🆘 **Crisis Detection** – Immediate crisis response with emergency hotline numbers
- 👨‍⚕️ **Counselor Channeling** – Book appointments and connect via Google Meet (Future development) 
- 📝 **Forum / Blog** – Share thoughts, stories, and mental health tips (Future development) 
- 💬 **Anonymous Group Chat** – Engage in peer-to-peer conversations safely (Future development) 


---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)  
- **Backend:** FastAPI (Python) with Groq LLM integration
- **Database:** Supabase (PostgreSQL) with real-time subscriptions
- **Authentication:** Supabase Auth  
- **Storage:** Supabase Storage  
- **AI/ML:** 
  - Groq API (LLaMA 3.1 for conversational AI)
  - Mental state prediction with heuristic fallback
  - Transformers & PyTorch for NLP
- **Real-time:** Supabase WebSocket subscriptions
- **Integrations:** Google Meet API (Future)  

---

## 🚀 Getting Started

### Prerequisites
- Install [Flutter](https://docs.flutter.dev/get-started/install) (>=3.27.3)  
- Install [Dart](https://dart.dev/get-dart)  
- Setup [Supabase Project](https://supabase.com/)  
- Configure your **API Keys** and **Environment Variables**  

### Installation
```bash
# Clone the repository
git clone https://github.com/DhanukaRathnayaka/Final_Year_Project.git

# Navigate to project directory
cd Final_Year_Project

# Get Flutter dependencies
flutter pub get

# Set up your Supabase configuration
# Create a new file lib/supabase_config.dart with your Supabase credentials:
# ```dart
# const supabaseUrl = 'YOUR_SUPABASE_URL';
# const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
# ```

# Run the Flutter app
flutter run
```

## 🤖 Setting up the Backend Server

The backend server is located in the `lib/Backend` directory and consists of:
- FastAPI server for the main API
- Mental Health Chatbot with sentiment analysis
- Supabase integration for data storage

### 1. Set up Python Environment

```bash
# Navigate to backend directory
cd lib/Backend

# Create and activate virtual environment
python -m venv venv
.\venv\Scripts\activate  # On Windows
# source venv/bin/activate  # On Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Install additional AI-related packages
pip install transformers torch numpy fastapi uvicorn python-dotenv supabase
```

### 2. Configure Environment Variables

Create a `.env` file in the `lib/Backend` directory:
```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_service_key

# Groq API Configuration (Required for AI Chatbot)
GROQ_API_KEY=your_groq_api_key

# Optional - OpenAI API
OPENAI_API_KEY=your_openai_api_key

# Debug Mode
DEBUG=false
```

**Note:** To get a Groq API key, visit [Groq Console](https://console.groq.com)

### 3. Set up Supabase Tables

Create the following tables in your Supabase database:

**Core Tables:**
- `conversations` – Store chat conversations and sessions
- `messages` – Store individual messages in conversations
- `users` – User profiles and metadata

**Mental Health Analysis:**
- `mental_state_reports` – Store mental state analysis results with dominant state and confidence

**Recommendations:**
- `doctors` – Mental health professionals database
- `entertainments` – Entertainment content (music, videos, exercises)
- `suggestions` – Daily wellness suggestions database
- `recommended_doctor` – User-doctor assignments
- `recommended_entertainments` – User entertainment recommendations
- `recommended_suggestions` – User suggestion recommendations

For detailed schema and RLS policies, see the documentation files in the project root.

### 4. Run the Backend Server

```bash
# From the lib/Backend directory
uvicorn app:app --reload --port 8000
```

The backend API will be available at:
👉 http://localhost:8000

Interactive API docs will be available at:
👉 http://localhost:8000/docs

## 📚 API Endpoints

### Chatbot
- **POST** `/api/chat` – Send message to AI chatbot

### Mental State Analysis
- **POST** `/api/predict-mental-state` – Predict mental state from text

### Recommendations
- **GET** `/ai-suggestions/suggestions/{user_id}` – Get personalized AI suggestions
- **GET** `/recommend_entertainment/api/suggestions/{user_id}` – Get entertainment recommendations
- **POST** `/recommend` – Get doctor recommendations
- **GET** `/api/suggestions/{user_id}` – Get combined suggestions

For detailed API documentation, visit the [API Documentation](BACKEND_AND_CHATBOT_FLOW_DOCUMENTATION.md).

## 📖 Documentation

Comprehensive documentation is available:
- **[Backend & Chatbot Flow](BACKEND_AND_CHATBOT_FLOW_DOCUMENTATION.md)** – Complete system architecture and flows
- **[Architecture Diagrams](ARCHITECTURE_FLOW_DIAGRAMS.md)** – Visual representations of all processes
- **[Implementation Guide](IMPLEMENTATION_GUIDE_AND_CODE_REFERENCE.md)** – Setup, configuration, and troubleshooting

## 🔄 Workflow

The SafeSpace system works as follows:

1. **User Authentication** → User logs in via Supabase Auth
2. **Chat Initiation** → User starts conversation with AI chatbot
3. **Real-time Messaging** → Messages sync via Supabase real-time subscriptions
4. **AI Processing** → Groq LLM generates compassionate responses
5. **Mental State Analysis** → After 5+ messages, system analyzes mental state
6. **Personalized Recommendations** → Based on dominant mental state:
   - AI-generated wellness suggestions
   - Entertainment content matching mood
   - Doctor matching by specialization
7. **Crisis Detection** → If crisis keywords detected, immediate hotline numbers provided


- **Kavindu Dedunupitiya** – Project Lead and UX UI Designer ( 22UG1-0812 )
- **Dhanuka Rathnayaka** – Fullstack Developer  ( 22UG1-0828 )
- **Gayanga Bandara** – Fullstack Developer  (22UG1-0285)


  