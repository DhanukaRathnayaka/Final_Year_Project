# SafeSpace 🛡️

SafeSpace is a Flutter-based mobile application focused on **mental health, counseling, and safe community interactions**.  
The app provides users with a supportive platform to connect with counselors, access resources, and engage in anonymous group discussions.  

---

## ✨ Features

- 🔐 **Authentication** – Secure sign-up and sign-in with Supabase
- 🎧 **Entertainment & Relaxation** – Meditation, music, and interactive exercises  
- 🤖 **AI Chatbot** – Mental health assistant to guide users with suggestions   
- 👨‍⚕️ **Counselor Channeling** – Book appointments and connect via Google Meet (Future devlopment) 
- 📝 **Forum / Blog** – Share thoughts, stories, and mental health tips  (Future devlopment) 
- 💬 **Anonymous Group Chat** – Engage in peer-to-peer conversations safely  (Future devlopment) 


---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)  
- **Backend:** Supabase (Postgres Database, API, Auth, Storage)  
- **Authentication:** Supabase Auth  
- **Database:** Supabase PostgreSQL  
- **Storage:** Supabase Storage  
- **Integrations:** Google Meet API  

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
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_service_key
```

### 3. Set up Supabase Tables

Create the following tables in your Supabase database:
- mental_state_reports
- doctors
- entertainments
- recommended_doctor
- recommended_entertainments
- conversations
- messages

(Schema details and RLS policies can be found in [database documentation](docs/database.md))

### 4. Run the Backend Server

```bash
# From the lib/Backend directory
uvicorn app:app --reload --port 8000
```

The backend API will be available at:
👉 http://localhost:8000

Interactive API docs will be available at:
👉 http://localhost:8000/docs

## 🧑‍💻 Contributors
- **Kavindu Dedunupitiya** – Project Lead and UX UI Designer ( 22UG1-0812 )
- **Dhanuka Rathnayaka** – Fullstack Developer  ( 22UG1-0828 )
- **Gayanga Bandara** – Fullstack Developer  (22UG1-0285)


  