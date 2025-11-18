-- ===================================================================
-- SAFESPACE EXERCISES - INSERT ALL EXERCISES
-- Copy and paste this entire script into Supabase SQL Editor
-- Then click "Execute"
-- ===================================================================

-- RELAXATION CATEGORY (5 exercises)
INSERT INTO exercises (category_name, category_image_path, exercise_name, exercise_description, duration, chat_flow, difficulty, is_active, created_at) VALUES 

('Relaxation', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop', 'Deep Breathing', 'Practice deep breathing technique for instant calm and stress relief', '5 min', '[
  {"message": "Welcome to Deep Breathing! 🌬️", "is_user": false, "options": ["Start Exercise"]},
  {"message": "Let''s begin. Find a comfortable position and breathe in slowly for 4 counts", "is_user": false, "options": ["Continue"]},
  {"message": "Hold your breath for 4 counts", "is_user": false, "options": ["Continue"]},
  {"message": "Breathe out slowly for 4 counts", "is_user": false, "options": ["Continue"]},
  {"message": "Great! Repeat this cycle 5 more times", "is_user": false, "options": ["Continue"]},
  {"message": "🎉 Congratulations! You''ve completed the exercise!", "is_user": false, "options": ["Done"]}
]', 'easy', true, NOW()),

('Relaxation', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop', 'Progressive Muscle Relaxation', 'Release tension from your body systematically through muscle groups', '10 min', '[
  {"message": "Welcome to Progressive Muscle Relaxation 💆", "is_user": false, "options": ["Start"]},
  {"message": "Start by tensing your feet muscles for 5 seconds", "is_user": false, "options": ["Next"]},
  {"message": "Now release and notice the relaxation difference", "is_user": false, "options": ["Continue"]},
  {"message": "Move to your legs and repeat the same process", "is_user": false, "options": ["Continue"]},
  {"message": "Continue with your abdomen, chest, arms, and shoulders", "is_user": false, "options": ["Continue"]},
  {"message": "Finish with your neck and face muscles", "is_user": false, "options": ["Continue"]},
  {"message": "✅ Excellent! Your body is now deeply relaxed", "is_user": false, "options": ["Done"]}
]', 'medium', true, NOW()),

('Relaxation', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop', 'Body Scan Meditation', 'Mindfully scan your body from head to toe for awareness and relaxation', '8 min', '[
  {"message": "Body Scan Meditation 🧘", "is_user": false, "options": ["Begin"]},
  {"message": "Close your eyes and bring attention to the top of your head", "is_user": false, "options": ["Continue"]},
  {"message": "Slowly move your awareness down through your face and neck", "is_user": false, "options": ["Continue"]},
  {"message": "Continue through your shoulders, arms, and hands", "is_user": false, "options": ["Continue"]},
  {"message": "Now focus on your chest, stomach, and lower back", "is_user": false, "options": ["Continue"]},
  {"message": "Move down to your hips, legs, and finally your feet", "is_user": false, "options": ["Continue"]},
  {"message": "🌟 Well done! You''ve completed the body scan", "is_user": false, "options": ["Finish"]}
]', 'easy', true, NOW()),

('Relaxation', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop', 'Guided Imagery', 'Visualize a peaceful place to calm your mind and body', '7 min', '[
  {"message": "Guided Imagery 🏞️", "is_user": false, "options": ["Start"]},
  {"message": "Imagine yourself in your favorite calm place - beach, forest, or mountains", "is_user": false, "options": ["Continue"]},
  {"message": "Notice the colors, textures, and light around you", "is_user": false, "options": ["Next"]},
  {"message": "Feel the gentle breeze and temperature on your skin", "is_user": false, "options": ["Continue"]},
  {"message": "Listen to the sounds of nature in this peaceful place", "is_user": false, "options": ["Continue"]},
  {"message": "Take a few deep breaths and enjoy this moment", "is_user": false, "options": ["Continue"]},
  {"message": "✨ Beautiful! You can return here anytime you need peace", "is_user": false, "options": ["Complete"]}
]', 'medium', true, NOW()),

('Relaxation', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=500&h=500&fit=crop', 'Tension Release', 'Quick exercise to release physical and mental tension', '3 min', '[
  {"message": "Tension Release ⚡", "is_user": false, "options": ["Start"]},
  {"message": "Shrug your shoulders up to your ears and hold for 3 seconds", "is_user": false, "options": ["Next"]},
  {"message": "Release suddenly and feel the relaxation", "is_user": false, "options": ["Continue"]},
  {"message": "Make fists with your hands and tense for 5 seconds", "is_user": false, "options": ["Continue"]},
  {"message": "Release and shake out your hands gently", "is_user": false, "options": ["Continue"]},
  {"message": "🎉 Tension released! Feel more relaxed and energized", "is_user": false, "options": ["Done"]}
]', 'easy', true, NOW()),

-- SLEEP SUPPORT CATEGORY (5 exercises)
('Sleep Support', 'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop', 'Sleep Meditation', 'Guided meditation to help you fall asleep peacefully', '15 min', '[
  {"message": "Sleep Meditation 🌙", "is_user": false, "options": ["Begin"]},
  {"message": "Find a comfortable position in bed and close your eyes", "is_user": false, "options": ["Ready"]},
  {"message": "Listen to the gentle sounds of rain and nature...", "is_user": false, "options": ["Continue"]},
  {"message": "Let your body sink deeper into the mattress with each breath", "is_user": false, "options": ["Continue"]},
  {"message": "Release all thoughts and worries from today", "is_user": false, "options": ["Continue"]},
  {"message": "Your mind is clear, your body is relaxed, sleep is coming", "is_user": false, "options": ["Continue"]},
  {"message": "Sleep well! You''ve completed the session 😴", "is_user": false, "options": ["Sleep"]}
]', 'easy', true, NOW()),
('Sleep Support', 'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop', 'Bedtime Routine', 'Prepare your mind and body for quality sleep', '8 min', '[
  {"message": "Bedtime Routine Guide 🛏️", "is_user": false, "options": ["Start"]},
  {"message": "Step 1: Put away your phone and devices from the bed", "is_user": false, "options": ["Done"]},
  {"message": "Step 2: Dim the lights and create a comfortable temperature", "is_user": false, "options": ["Continue"]},
  {"message": "Step 3: Take 5 deep breaths to calm your nervous system", "is_user": false, "options": ["Continue"]},
  {"message": "Step 4: Imagine a peaceful place where you feel safe", "is_user": false, "options": ["Continue"]},
  {"message": "You''re ready for sleep! Goodnight 😴", "is_user": false, "options": ["Sleep"]}
]', 'easy', true, NOW()),
('Sleep Support', 'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop', 'Relaxation for Sleep', 'Release tension before bed for better sleep quality', '10 min', '[
  {"message": "Relaxation for Sleep 😴", "is_user": false, "options": ["Begin"]},
  {"message": "Lie in bed and tense each muscle group for 3 seconds", "is_user": false, "options": ["Start"]},
  {"message": "Feet and legs - tense and release", "is_user": false, "options": ["Continue"]},
  {"message": "Abdomen and chest - tense and release", "is_user": false, "options": ["Continue"]},
  {"message": "Arms and shoulders - tense and release", "is_user": false, "options": ["Continue"]},
  {"message": "Face and head - tense and release", "is_user": false, "options": ["Continue"]},
  {"message": "Your body is now relaxed and ready for sleep 🌟", "is_user": false, "options": ["Sleep"]}
]', 'medium', true, NOW()),
('Sleep Support', 'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop', 'Counting Down Sleep', 'Use counting to quiet your mind and drift to sleep', '12 min', '[
  {"message": "Counting Down Sleep 📊", "is_user": false, "options": ["Start"]},
  {"message": "We''ll count backwards from 100 to help you fall asleep", "is_user": false, "options": ["Begin"]},
  {"message": "100... 99... 98... 97... 96... 95... Notice each number", "is_user": false, "options": ["Continue"]},
  {"message": "The numbers get slower... 85... 75... 65... 55...", "is_user": false, "options": ["Continue"]},
  {"message": "Your mind is quieter now... 45... 35... 25...", "is_user": false, "options": ["Continue"]},
  {"message": "Almost there... 15... 10... 5... 0... Sleep now 🌙", "is_user": false, "options": ["Sleep"]}
]', 'medium', true, NOW()),
('Sleep Support', 'https://images.unsplash.com/photo-1518805185286-7a7e4c50a2b7?w=500&h=500&fit=crop', 'Sleep Stories', 'Listen to a calming sleep story to drift off', '18 min', '[
  {"message": "Sleep Stories 📖", "is_user": false, "options": ["Begin"]},
  {"message": "Once upon a time, in a quiet village by the sea...", "is_user": false, "options": ["Listen"]},
  {"message": "There lived a peaceful cottage surrounded by gardens", "is_user": false, "options": ["Continue"]},
  {"message": "Every evening, the owners would sit and watch the sunset", "is_user": false, "options": ["Continue"]},
  {"message": "The waves gently rolled, creating a soothing rhythm", "is_user": false, "options": ["Continue"]},
  {"message": "And as the stars appeared, sleep came naturally...", "is_user": false, "options": ["Sleep"]}
]', 'easy', true, NOW()),

-- PERSONAL GROWTH CATEGORY (5 exercises)
('Personal Growth', 'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop', 'Daily Affirmations', 'Positive affirmations to boost confidence and mindset', '3 min', '[
  {"message": "Daily Affirmations 💪", "is_user": false, "options": ["Start"]},
  {"message": "I am capable and strong", "is_user": false, "options": ["Next"]},
  {"message": "I can achieve my goals", "is_user": false, "options": ["Next"]},
  {"message": "I am worthy of success and happiness", "is_user": false, "options": ["Next"]},
  {"message": "I choose positivity and growth every day", "is_user": false, "options": ["Next"]},
  {"message": "Today will be great! 🌟", "is_user": false, "options": ["Finish"]}
]', 'easy', true, NOW()),
('Personal Growth', 'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop', 'Gratitude Practice', 'Reflect on what you''re grateful for today', '5 min', '[
  {"message": "Gratitude Practice 🙏", "is_user": false, "options": ["Begin"]},
  {"message": "Think of 3 things you''re grateful for today", "is_user": false, "options": ["Continue"]},
  {"message": "Remember to appreciate the small moments", "is_user": false, "options": ["Reflect"]},
  {"message": "Gratitude brings peace, joy, and positive energy", "is_user": false, "options": ["Continue"]},
  {"message": "Practice this daily for the best results 💝", "is_user": false, "options": ["Complete"]}
]', 'easy', true, NOW()),
('Personal Growth', 'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop', 'Goal Setting', 'Set meaningful goals for personal growth', '6 min', '[
  {"message": "Goal Setting 🎯", "is_user": false, "options": ["Start"]},
  {"message": "What do you want to achieve in the next 3 months?", "is_user": false, "options": ["Continue"]},
  {"message": "Write it down clearly and make it specific", "is_user": false, "options": ["Next"]},
  {"message": "Break it into smaller, actionable steps", "is_user": false, "options": ["Continue"]},
  {"message": "Commit to taking one step today", "is_user": false, "options": ["Commit"]},
  {"message": "You''ve got this! Start today 🚀", "is_user": false, "options": ["Done"]}
]', 'medium', true, NOW()),
('Personal Growth', 'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop', 'Self-Compassion', 'Practice kindness and compassion towards yourself', '7 min', '[
  {"message": "Self-Compassion 💖", "is_user": false, "options": ["Begin"]},
  {"message": "Place your hand on your heart and take a deep breath", "is_user": false, "options": ["Continue"]},
  {"message": "Speak to yourself as you would to a good friend", "is_user": false, "options": ["Next"]},
  {"message": "You deserve kindness, understanding, and support", "is_user": false, "options": ["Continue"]},
  {"message": "Mistakes are part of growth, not failure", "is_user": false, "options": ["Continue"]},
  {"message": "I am doing my best and that is enough ✨", "is_user": false, "options": ["Finish"]}
]', 'medium', true, NOW()),
('Personal Growth', 'https://images.unsplash.com/photo-1552881910-efaa4987b8dc?w=500&h=500&fit=crop', 'Mindfulness Practice', 'Be present and aware in this moment', '10 min', '[
  {"message": "Mindfulness Practice 🧘", "is_user": false, "options": ["Begin"]},
  {"message": "Sit comfortably and notice your surroundings", "is_user": false, "options": ["Start"]},
  {"message": "What do you see, hear, smell, taste, and feel?", "is_user": false, "options": ["Continue"]},
  {"message": "Bring your attention to your breath without judgment", "is_user": false, "options": ["Focus"]},
  {"message": "If thoughts arise, notice them and let them pass", "is_user": false, "options": ["Continue"]},
  {"message": "Return to the present moment, here and now", "is_user": false, "options": ["Continue"]},
  {"message": "🌟 You''re present and aware. Well done!", "is_user": false, "options": ["Complete"]}
]', 'medium', true, NOW());

-- Verify insertion
SELECT COUNT(*) as total_exercises, 
       COUNT(DISTINCT category_name) as total_categories 
FROM exercises WHERE is_active = true;
