# SQL Scripts - Copy & Paste Ready

## 🔧 Step 1: Create Tables

Copy and paste this entire block into Supabase SQL Editor, then click "Execute":

```sql
-- Create exercises table (main data store)
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(255) NOT NULL,
  category_image_path TEXT,
  exercise_name VARCHAR(255) NOT NULL,
  exercise_description TEXT,
  duration VARCHAR(50) DEFAULT '5 min',
  chat_flow JSONB DEFAULT '[]'::jsonb,
  difficulty VARCHAR(50) DEFAULT 'medium',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create exercise_completions table (track user progress)
CREATE TABLE exercise_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE,
  duration_seconds INTEGER,
  completed_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_exercises_category ON exercises(category_name);
CREATE INDEX idx_exercises_active ON exercises(is_active);
CREATE INDEX idx_completions_user ON exercise_completions(user_id);
CREATE INDEX idx_completions_date ON exercise_completions(DATE(completed_at));
```

---

## 📝 Step 2: Insert Sample Data

Copy and paste this entire block into Supabase SQL Editor, then click "Execute":

```sql
-- Insert sample exercises
INSERT INTO exercises (
  category_name, 
  category_image_path, 
  exercise_name, 
  exercise_description, 
  duration, 
  chat_flow
) VALUES 
(
  'Relaxation',
  'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop',
  'Deep Breathing',
  'Practice deep breathing technique for instant calm',
  '5 min',
  '[
    {"message": "Welcome to Deep Breathing!", "is_user": false, "options": ["Start Exercise"]},
    {"message": "Let''s begin. Breathe in slowly for 4 counts", "is_user": false, "options": ["Continue"]},
    {"message": "Hold your breath for 4 counts", "is_user": false, "options": ["Continue"]},
    {"message": "Breathe out slowly for 4 counts", "is_user": false, "options": ["Continue"]},
    {"message": "🎉 Congratulations! You''ve completed the exercise!", "is_user": false, "options": ["Done"]}
  ]'::jsonb
),
(
  'Relaxation',
  'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop',
  'Progressive Muscle Relaxation',
  'Release tension from your body systematically',
  '10 min',
  '[
    {"message": "Welcome to Progressive Muscle Relaxation", "is_user": false, "options": ["Start"]},
    {"message": "Start by tensing your feet for 5 seconds", "is_user": false, "options": ["Next"]},
    {"message": "Release and notice the difference", "is_user": false, "options": ["Continue"]},
    {"message": "Move to your legs and repeat", "is_user": false, "options": ["Continue"]},
    {"message": "✅ Excellent! Your relaxation is complete", "is_user": false, "options": ["Done"]}
  ]'::jsonb
),
(
  'Sleep Support',
  'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop',
  'Sleep Meditation',
  'Guided meditation to help you fall asleep peacefully',
  '15 min',
  '[
    {"message": "Welcome to Sleep Meditation", "is_user": false, "options": ["Begin"]},
    {"message": "Find a comfortable position and close your eyes", "is_user": false, "options": ["Ready"]},
    {"message": "Listen to the calming sounds of nature...", "is_user": false, "options": ["Continue"]},
    {"message": "Let your mind drift away", "is_user": false, "options": ["Continue"]},
    {"message": "Sleep well! You''ve completed the session 🌙", "is_user": false, "options": ["Done"]}
  ]'::jsonb
),
(
  'Sleep Support',
  'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop',
  'Bedtime Routine',
  'Prepare your mind and body for better sleep quality',
  '8 min',
  '[
    {"message": "Bedtime Routine Guide", "is_user": false, "options": ["Start"]},
    {"message": "Step 1: Put away your phone and dim the lights", "is_user": false, "options": ["Done"]},
    {"message": "Step 2: Take some deep breaths and relax your body", "is_user": false, "options": ["Continue"]},
    {"message": "Step 3: Imagine a peaceful place", "is_user": false, "options": ["Continue"]},
    {"message": "You''re ready for sleep! Goodnight 😴", "is_user": false, "options": ["Sleep"]}
  ]'::jsonb
),
(
  'Personal Growth',
  'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop',
  'Daily Affirmations',
  'Positive affirmations to boost your confidence and mindset',
  '3 min',
  '[
    {"message": "Daily Affirmations", "is_user": false, "options": ["Start"]},
    {"message": "I am capable and strong", "is_user": false, "options": ["Next"]},
    {"message": "I can achieve my goals", "is_user": false, "options": ["Next"]},
    {"message": "I am worthy of success and happiness", "is_user": false, "options": ["Next"]},
    {"message": "Today will be great! 💪", "is_user": false, "options": ["Finish"]}
  ]'::jsonb
),
(
  'Personal Growth',
  'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop',
  'Gratitude Practice',
  'Reflect on what you''re grateful for today',
  '5 min',
  '[
    {"message": "Gratitude Practice", "is_user": false, "options": ["Begin"]},
    {"message": "Think of 3 things you''re grateful for today", "is_user": false, "options": ["Continue"]},
    {"message": "Remember to appreciate the small moments", "is_user": false, "options": ["Reflect"]},
    {"message": "Gratitude brings peace and joy 🙏", "is_user": false, "options": ["Continue"]},
    {"message": "Well done! Practice this daily for best results", "is_user": false, "options": ["Complete"]}
  ]'::jsonb
);
```

---

## 🧪 Step 3: Verify Data (Optional)

To verify everything was inserted correctly, run this query:

```sql
-- Count exercises by category
SELECT 
  category_name,
  COUNT(*) as exercise_count
FROM exercises
WHERE is_active = true
GROUP BY category_name
ORDER BY category_name;

-- Expected output:
-- Personal Growth | 2
-- Relaxation | 2
-- Sleep Support | 2
```

---

## 🔍 Step 4: Check Sample Data

To see all your exercises:

```sql
SELECT 
  id,
  exercise_name,
  category_name,
  duration,
  is_active
FROM exercises
ORDER BY category_name, exercise_name;
```

---

## ❌ If You Need to Delete Everything (Start Over)

```sql
-- Delete all completions first (due to foreign key)
DELETE FROM exercise_completions;

-- Delete all exercises
DELETE FROM exercises;
```

---

## ✅ Verification Checklist

After running the scripts, verify:

```sql
-- Check exercises table has 6 rows
SELECT COUNT(*) as total_exercises FROM exercises;
-- Should return: 6

-- Check categories
SELECT DISTINCT category_name FROM exercises;
-- Should return: Personal Growth, Relaxation, Sleep Support

-- Check chat flows are stored as JSONB
SELECT exercise_name, jsonb_array_length(chat_flow) as message_count 
FROM exercises;
-- Should show each exercise has 3-5 messages
```

---

**That's it!** 🎉

Your database is now ready. The app can connect and load exercises!
