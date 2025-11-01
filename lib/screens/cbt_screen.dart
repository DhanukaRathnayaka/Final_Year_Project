import 'package:flutter/material.dart';

class CBTExerciseScreen extends StatelessWidget {
  final List<ExerciseCategory> categories = [
    ExerciseCategory(
      name: 'Get Confidence',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(7).png',
      exercises: [
        Exercise(
          name: 'Future Visitor',
          duration: '10 min',
          chatFlow: [
            ChatMessage(message: "Hello there!", isUser: false, options: []),
            ChatMessage(
              message: "Ready for a unique journey today?",
              isUser: false,
              options: ["Sure, what's the plan?"],
            ),
            ChatMessage(
              message:
                  "Great! For now, just stay where you are, relax, and take a slow deep breath.",
              isUser: false,
              options: ["Okay, I’m ready."],
            ),
            ChatMessage(
              message:
                  "Excellent. Now, think of a recent moment when you felt proud or accomplished something meaningful.",
              isUser: false,
              options: [],
            ),
            ChatMessage(
              message:
                  "Hold that moment in your mind. Imagine your future self—stronger, calmer, and wiser—visiting you today.",
              isUser: false,
              options: [],
            ),
            ChatMessage(
              message:
                  "This future version of you has already overcome the challenges you're facing now. What advice do they have for you?",
              isUser: false,
              options: [],
            ),
            ChatMessage(
              message:
                  "Take a moment to listen to that inner voice. How does that advice make you feel?",
              isUser: false,
              options: ["Relieved", "Motivated", "Emotional"],
            ),
            ChatMessage(
              message:
                  "Beautiful. Remember, that wisdom is already within you—you just practiced listening to it.",
              isUser: false,
              options: ["That felt good", "Thank you"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Future Visitor exercise. Carry that feeling of calm confidence with you today.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Positive Self-Talk',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi there! Today we’ll focus on building a kinder inner voice.",
              isUser: false,
              options: ["Let's begin!"],
            ),
            ChatMessage(
              message:
                  "Think about a recent situation where you were hard on yourself.",
              isUser: false,
              options: ["I remember one."],
            ),
            ChatMessage(
              message: "What did your inner voice say in that moment?",
              isUser: false,
              options: [
                "It was negative",
                "It was critical",
                "It was discouraging",
              ],
            ),
            ChatMessage(
              message:
                  "Now imagine someone you care about was in the same situation. What would you say to comfort them?",
              isUser: false,
              options: ["I’d be kind to them", "I’d encourage them"],
            ),
            ChatMessage(
              message:
                  "Exactly — that’s the tone we want your inner voice to have: kind, patient, and supportive.",
              isUser: false,
              options: ["Makes sense", "I’ll try that"],
            ),
            ChatMessage(
              message:
                  "Let’s rephrase your earlier self-talk in a positive way. For example: 'I’m learning and improving each day.'",
              isUser: false,
              options: ["I like that", "Let me try one"],
            ),
            ChatMessage(
              message: "How does that new phrase make you feel?",
              isUser: false,
              options: ["Encouraged", "Hopeful", "Calm"],
            ),
            ChatMessage(
              message:
                  "That’s great! Remember, speaking to yourself with kindness builds strength and motivation.",
              isUser: false,
              options: ["Continue", "True"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Positive Self-Talk exercise. Keep using that gentle, supportive inner voice every day.",
              isUser: false,
              options: ["Done", "Thanks for the session"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Sleep Support',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(8).png',
      exercises: [
        Exercise(
          name: 'Sleep Meditation',
          duration: '10 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Welcome! Let’s take a few minutes to relax and prepare your mind for restful sleep.",
              isUser: false,
              options: ["I’m ready", "Let’s start"],
            ),
            ChatMessage(
              message:
                  "Find a comfortable position, close your eyes, and take a slow, deep breath in through your nose…",
              isUser: false,
              options: ["Done", "Breathing now"],
            ),
            ChatMessage(
              message:
                  "Now gently exhale through your mouth. Feel your shoulders drop and your body begin to loosen.",
              isUser: false,
              options: ["Feeling relaxed", "Continuing"],
            ),
            ChatMessage(
              message:
                  "Good. As you breathe slowly, focus on the rhythm of your breath — in and out, calm and steady.",
              isUser: false,
              options: ["Inhale... exhale...", "I’m following"],
            ),
            ChatMessage(
              message:
                  "Imagine a soft wave of calm energy starting at your feet and slowly moving upward through your body.",
              isUser: false,
              options: ["Visualizing it", "Feels nice"],
            ),
            ChatMessage(
              message:
                  "With each breath, your body becomes heavier, your thoughts slower, and your mind quieter.",
              isUser: false,
              options: ["I feel calmer", "I’m relaxing"],
            ),
            ChatMessage(
              message:
                  "If any thoughts appear, don’t fight them — just let them drift away like clouds passing in the sky.",
              isUser: false,
              options: ["I’ll try that", "Letting go"],
            ),
            ChatMessage(
              message:
                  "Now repeat silently: ‘I am safe. I am calm. I am ready to rest.’",
              isUser: false,
              options: ["Repeating it", "Done"],
            ),
            ChatMessage(
              message:
                  "Wonderful. Allow yourself to sink deeper into comfort. Your mind and body are ready for peaceful sleep.",
              isUser: false,
              options: ["Feeling sleepy", "Thank you"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Sleep Meditation exercise. Rest well and wake up refreshed tomorrow.",
              isUser: false,
              options: ["Goodnight", "Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Insomnia Relief',
          duration: '10 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi there. Trouble sleeping? Let’s calm your mind and body together.",
              isUser: false,
              options: ["Let's begin"],
            ),
            ChatMessage(
              message:
                  "First, find a comfortable position and take a deep breath in through your nose… then slowly exhale through your mouth.",
              isUser: false,
              options: ["Done"],
            ),
            ChatMessage(
              message:
                  "Good. Now, gently notice the sensations around you — the softness of your bed, the quiet in the room, the air touching your skin.",
              isUser: false,
              options: ["I’m noticing"],
            ),
            ChatMessage(
              message:
                  "Let’s focus on releasing tension. Starting with your feet, imagine them relaxing completely. Feel them grow heavy and still.",
              isUser: false,
              options: ["Continuing"],
            ),
            ChatMessage(
              message:
                  "Now move that relaxation upward — through your legs, your stomach, your chest, and finally your shoulders and neck.",
              isUser: false,
              options: ["I’m following"],
            ),
            ChatMessage(
              message:
                  "If your mind starts to wander, gently bring it back to your breathing. You don’t need to force anything — just breathe.",
              isUser: false,
              options: ["Okay"],
            ),
            ChatMessage(
              message:
                  "Now, repeat this silently in your mind: ‘I am safe. I can rest. My body knows how to sleep.’",
              isUser: false,
              options: ["Repeating it"],
            ),
            ChatMessage(
              message:
                  "Each breath slows down your heart rate and relaxes your muscles even more.",
              isUser: false,
              options: ["I feel calmer"],
            ),
            ChatMessage(
              message:
                  "Imagine yourself floating on a gentle cloud — supported, calm, and completely at ease.",
              isUser: false,
              options: ["Feels peaceful"],
            ),
            ChatMessage(
              message:
                  "You’re doing great. Allow yourself to rest now. Even if sleep takes time, your body is learning to relax again.",
              isUser: false,
              options: ["Goodnight"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Personal Growth',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design.png',
      exercises: [
        Exercise(
          name: 'My Strengths and Qualities',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll focus on recognizing your personal strengths and qualities.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Think of a time when you successfully overcame a challenge. What strength helped you through it?",
              isUser: false,
              options: ["I know it"],
            ),
            ChatMessage(
              message:
                  "Great! Now, can you identify another quality you admire about yourself?",
              isUser: false,
              options: ["Yes, I can"],
            ),
            ChatMessage(
              message: "Wonderful. How does using this strength make you feel?",
              isUser: false,
              options: ["Confident"],
            ),
            ChatMessage(
              message:
                  "Think of a recent situation where you applied one of your strengths. How did it help?",
              isUser: false,
              options: ["I remember"],
            ),
            ChatMessage(
              message:
                  "Now, imagine using this strength in the future to handle a challenge. How would it help?",
              isUser: false,
              options: ["I can see it"],
            ),
            ChatMessage(
              message:
                  "Amazing! By recognizing and using your strengths, you can handle challenges more effectively and feel empowered.",
              isUser: false,
              options: ["I feel empowered"],
            ),
            ChatMessage(
              message:
                  "Take a moment to appreciate yourself and your qualities. You’ve completed this exercise!",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Anger Traffic Light',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll learn to manage anger using the Traffic Light method.",
              isUser: false,
              options: ["Let's begin"],
            ),
            ChatMessage(
              message:
                  "First, think of a recent moment when you felt angry. Can you recall it clearly?",
              isUser: false,
              options: ["Yes, I remember"],
            ),
            ChatMessage(
              message:
                  "Great. Now, imagine a traffic light. Red means STOP, yellow means SLOW DOWN, and green means GO.",
              isUser: false,
              options: ["I’m visualizing it"],
            ),
            ChatMessage(
              message:
                  "When you feel anger rising, imagine hitting RED — pause and take a deep breath.",
              isUser: false,
              options: ["Pausing"],
            ),
            ChatMessage(
              message:
                  "Next, move to YELLOW — slow down your thoughts and reflect: what triggered this anger?",
              isUser: false,
              options: ["Reflecting"],
            ),
            ChatMessage(
              message:
                  "Finally, GREEN — think of a calm, constructive response you can take instead of reacting impulsively.",
              isUser: false,
              options: ["I have a response"],
            ),
            ChatMessage(
              message:
                  "Well done! Practicing this regularly helps you respond thoughtfully rather than react with anger.",
              isUser: false,
              options: ["I understand"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Anger Traffic Light exercise. Remember to use this method whenever anger arises.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Stress Toolkit',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(1).png',
      exercises: [
        Exercise(
          name: 'Balloon Breathing',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice Balloon Breathing to relax and release stress.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Sit comfortably and imagine holding a balloon in front of you.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath in through your nose and imagine inflating the balloon with your breath.",
              isUser: false,
              options: ["Breathing in"],
            ),
            ChatMessage(
              message:
                  "Hold your breath for a moment, feeling the balloon expand and your body filling with calm.",
              isUser: false,
              options: ["Holding it"],
            ),
            ChatMessage(
              message:
                  "Exhale slowly through your mouth and imagine the balloon gently deflating, carrying away tension.",
              isUser: false,
              options: ["Exhaling"],
            ),
            ChatMessage(
              message:
                  "Repeat this process several times, noticing how each breath relaxes your body further.",
              isUser: false,
              options: ["Continuing"],
            ),
            ChatMessage(
              message:
                  "Feel your body lighter and your mind calmer with each balloon breath.",
              isUser: false,
              options: ["I feel calmer"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Balloon Breathing exercise. Carry this calm and relaxed feeling with you.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Countdown',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll use the Countdown exercise to focus your mind and reduce stress.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Sit comfortably and take a slow, deep breath in through your nose.",
              isUser: false,
              options: ["Breathing in"],
            ),
            ChatMessage(
              message:
                  "Exhale gently through your mouth, letting go of any tension.",
              isUser: false,
              options: ["Exhaling"],
            ),
            ChatMessage(
              message:
                  "Now, silently begin counting down from 10 to 1 with each breath.",
              isUser: false,
              options: ["Counting now"],
            ),
            ChatMessage(
              message:
                  "As you count down, imagine your body and mind relaxing more with each number.",
              isUser: false,
              options: ["Feeling relaxed"],
            ),
            ChatMessage(
              message:
                  "If your mind wanders, gently bring it back to the countdown and your breath.",
              isUser: false,
              options: ["Focusing again"],
            ),
            ChatMessage(
              message:
                  "When you reach 1, notice how calm and centered you feel.",
              isUser: false,
              options: ["I feel calm"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Countdown exercise. Carry this focused and relaxed feeling with you.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Zen Zone',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(2).png',
      exercises: [
        Exercise(
          name: 'Imaginary Lemon Squeeze',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice the Imaginary Lemon Squeeze exercise to release tension and stress.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message: "Imagine holding a fresh, juicy lemon in your hands.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Now squeeze the lemon tightly, noticing the tension in your hands and arms.",
              isUser: false,
              options: ["Squeezing it"],
            ),
            ChatMessage(
              message:
                  "Hold the squeeze for a few seconds, feeling the effort and tension.",
              isUser: false,
              options: ["Holding it"],
            ),
            ChatMessage(
              message:
                  "Slowly release your grip and feel the tension melting away.",
              isUser: false,
              options: ["Releasing it"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath and imagine the lemon juice carrying away stress and discomfort.",
              isUser: false,
              options: ["Breathing"],
            ),
            ChatMessage(
              message:
                  "Repeat the process if you like, noticing how your body relaxes more with each squeeze and release.",
              isUser: false,
              options: ["Repeating it"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Imaginary Lemon Squeeze exercise. Carry this sense of relaxation with you.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Colour Inhale',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll use Colour Inhale to relax your mind and body.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Close your eyes and take a slow, deep breath in through your nose.",
              isUser: false,
              options: ["Breathing in"],
            ),
            ChatMessage(
              message:
                  "Imagine inhaling a calming color, like blue or green, filling your body with peace.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Hold your breath for a moment, feeling the color spreading through you.",
              isUser: false,
              options: ["Holding it"],
            ),
            ChatMessage(
              message:
                  "Exhale slowly, imagining tension leaving your body as a grey or dark color.",
              isUser: false,
              options: ["Exhaling"],
            ),
            ChatMessage(
              message:
                  "Repeat this process, breathing in calm and exhaling tension with each cycle.",
              isUser: false,
              options: ["Continuing"],
            ),
            ChatMessage(
              message:
                  "Notice how your body and mind feel lighter and more relaxed.",
              isUser: false,
              options: ["I feel calmer"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Colour Inhale exercise. Carry this calm energy with you.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Emotional Reagulation',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(3).png',
      exercises: [
        Exercise(
          name: 'Ice Grip Test',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll try the Ice Grip Test to notice tension and practice releasing it.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Imagine holding a piece of ice tightly in your hand. Notice the tension in your fingers and hand.",
              isUser: false,
              options: ["Feeling it"],
            ),
            ChatMessage(
              message:
                  "Hold the ice for a few seconds, focusing on the sensations and tension.",
              isUser: false,
              options: ["Holding it"],
            ),
            ChatMessage(
              message:
                  "Now slowly release your grip and notice how your hand feels as it relaxes.",
              isUser: false,
              options: ["Releasing it"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath and feel the tension leaving your body with the exhale.",
              isUser: false,
              options: ["Feeling relaxed"],
            ),
            ChatMessage(
              message:
                  "Repeat the process if you like, noticing how tension builds and then releases each time.",
              isUser: false,
              options: ["Repeating it"],
            ),
            ChatMessage(
              message:
                  "Notice the difference in your hand and body after releasing the tension. Feel calmer and lighter.",
              isUser: false,
              options: ["I feel it"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Ice Grip Test exercise. Use this method whenever you feel stress building up.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Letting Go',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice letting go of thoughts or feelings that no longer serve you.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Think of something that’s bothering you or holding you back.",
              isUser: false,
              options: ["I know it"],
            ),
            ChatMessage(
              message:
                  "Acknowledge it without judgment. Accept that it exists in this moment.",
              isUser: false,
              options: ["Acknowledged"],
            ),
            ChatMessage(
              message:
                  "Now, imagine holding it in your hands and slowly opening them to release it.",
              isUser: false,
              options: ["Releasing it"],
            ),
            ChatMessage(
              message:
                  "Visualize the thought or feeling floating away, getting smaller and lighter as it drifts.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath and feel the sense of freedom and space created as you let it go.",
              isUser: false,
              options: ["Feeling it"],
            ),
            ChatMessage(
              message:
                  "If it comes back, gently acknowledge it and release it again.",
              isUser: false,
              options: ["Will do"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Letting Go exercise. Carry this sense of ease and lightness with you.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Exposure Therapy',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(4).png',
      exercises: [
        Exercise(
          name: 'Good World',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll focus on creating a positive mental space called 'Good World.'",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Close your eyes and imagine a place where everything feels safe, calm, and happy.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Add details to this place — colors, sounds, scents, and textures that make it comforting.",
              isUser: false,
              options: ["Adding details"],
            ),
            ChatMessage(
              message:
                  "Now imagine yourself walking or sitting in this world, feeling completely at peace.",
              isUser: false,
              options: ["I feel peaceful"],
            ),
            ChatMessage(
              message:
                  "Notice any positive sensations or emotions as you explore your Good World.",
              isUser: false,
              options: ["Feeling them"],
            ),
            ChatMessage(
              message:
                  "If any stress or worries arise, imagine them gently leaving as you stay in your Good World.",
              isUser: false,
              options: ["Letting them go"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath and fully enjoy the calm and happiness of this space.",
              isUser: false,
              options: ["Enjoying it"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Good World exercise. Remember you can return here anytime for peace and relaxation.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Phrasing Yourself',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice expressing your thoughts and feelings clearly and kindly.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Think of a situation where you wanted to speak up but didn’t know how to phrase it.",
              isUser: false,
              options: ["I remember one"],
            ),
            ChatMessage(
              message:
                  "What was the main point or feeling you wanted to communicate?",
              isUser: false,
              options: ["I know it"],
            ),
            ChatMessage(
              message:
                  "Now, imagine expressing it calmly and respectfully, using 'I' statements. For example: 'I feel… when… because…'",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Practice saying your statement silently or in your mind, focusing on clarity and honesty.",
              isUser: false,
              options: ["Practicing now"],
            ),
            ChatMessage(
              message:
                  "Notice how this phrasing allows you to express yourself without causing conflict or guilt.",
              isUser: false,
              options: ["I notice it"],
            ),
            ChatMessage(
              message:
                  "Think of a real situation where you can use this phrasing to communicate effectively.",
              isUser: false,
              options: ["I can do that"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Phrasing Yourself exercise. Keep practicing clear, kind communication in your daily life.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Relaxation Techniques',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(5).png',
      exercises: [
        Exercise(
          name: 'Calm Mind',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice calming your mind and reducing stress.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Find a comfortable position and take a slow, deep breath in through your nose…",
              isUser: false,
              options: ["Breathing now"],
            ),
            ChatMessage(
              message:
                  "Exhale gently through your mouth. Feel your body starting to relax.",
              isUser: false,
              options: ["Feeling relaxed"],
            ),
            ChatMessage(
              message:
                  "Focus your attention on your breath. Notice it flowing in and out naturally.",
              isUser: false,
              options: ["I’m focusing"],
            ),
            ChatMessage(
              message:
                  "If your mind wanders, gently bring it back to your breathing without judgment.",
              isUser: false,
              options: ["I will"],
            ),
            ChatMessage(
              message:
                  "Now, imagine a peaceful scene — a calm beach, a quiet forest, or any place that feels safe to you.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "With each breath, feel your mind becoming clearer and calmer, like a still lake.",
              isUser: false,
              options: ["I feel calmer"],
            ),
            ChatMessage(
              message:
                  "Notice any tension leaving your body. Allow yourself to simply be in this calm state.",
              isUser: false,
              options: ["I’m relaxed"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Calm Mind exercise. Carry this sense of peace with you through your day.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: 'Forget Unwanted Thoughts',
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll practice letting go of unwanted thoughts.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Think of a thought that keeps bothering you. Can you identify it clearly?",
              isUser: false,
              options: ["Yes, I can"],
            ),
            ChatMessage(
              message:
                  "Acknowledge the thought without judging yourself. Simply notice it exists.",
              isUser: false,
              options: ["Noted"],
            ),
            ChatMessage(
              message:
                  "Now, imagine placing that thought in a balloon and letting it float away.",
              isUser: false,
              options: ["Visualizing it"],
            ),
            ChatMessage(
              message:
                  "Watch the balloon drift higher and higher, carrying the thought out of your mind.",
              isUser: false,
              options: ["I see it"],
            ),
            ChatMessage(
              message:
                  "Take a deep breath and feel the space created in your mind as the thought leaves.",
              isUser: false,
              options: ["Feeling it"],
            ),
            ChatMessage(
              message:
                  "If the thought returns, gently place it in another balloon and release it again.",
              isUser: false,
              options: ["Will do"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Forget Unwanted Thoughts exercise. Enjoy the calm and clarity in your mind.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
    ExerciseCategory(
      name: 'Thought Management',
      imagePath:
          'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(6).png',
      exercises: [
        Exercise(
          name: 'Thought Diary',
          duration: '10 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll track your thoughts to better understand them.",
              isUser: false,
              options: ["Let's start"],
            ),
            ChatMessage(
              message:
                  "Think of a situation recently that caused strong emotions. Can you recall it?",
              isUser: false,
              options: ["Yes, I remember"],
            ),
            ChatMessage(
              message:
                  "Great. What thoughts went through your mind at that time?",
              isUser: false,
              options: ["I’m thinking"],
            ),
            ChatMessage(
              message: "How did those thoughts make you feel emotionally?",
              isUser: false,
              options: ["I felt anxious", "I felt sad", "I felt angry"],
            ),
            ChatMessage(
              message:
                  "Now, let’s examine those thoughts. Are they based on facts, assumptions, or feelings?",
              isUser: false,
              options: ["Analyzing now"],
            ),
            ChatMessage(
              message:
                  "Can you identify a more balanced or helpful way to think about the situation?",
              isUser: false,
              options: ["I can try"],
            ),
            ChatMessage(
              message:
                  "Excellent. How does this new perspective make you feel?",
              isUser: false,
              options: ["I feel calmer", "I feel more in control"],
            ),
            ChatMessage(
              message:
                  "Remember, keeping a thought diary regularly helps you recognize patterns and respond more positively.",
              isUser: false,
              options: ["I’ll do that"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the Thought Diary exercise. Keep practicing to strengthen your awareness.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
        Exercise(
          name: "Escaping 'Should' Traps",
          duration: '8 min',
          chatFlow: [
            ChatMessage(
              message:
                  "Hi! Today we’ll work on identifying and escaping 'should' statements that cause stress.",
              isUser: false,
              options: ["Let's begin"],
            ),
            ChatMessage(
              message:
                  "Think about a recent situation where you felt pressured or guilty. Can you recall it?",
              isUser: false,
              options: ["Yes, I remember"],
            ),
            ChatMessage(
              message:
                  "What 'should' statements were running through your mind? For example: 'I should have done better.'",
              isUser: false,
              options: ["I know them"],
            ),
            ChatMessage(
              message:
                  "Notice how these statements make you feel — anxious, frustrated, or guilty?",
              isUser: false,
              options: ["I feel that"],
            ),
            ChatMessage(
              message:
                  "Now, reframe those statements into more realistic or compassionate thoughts. For example: 'I did my best and I am learning.'",
              isUser: false,
              options: ["Trying it now"],
            ),
            ChatMessage(
              message: "How does this new perspective change your feelings?",
              isUser: false,
              options: ["I feel relieved"],
            ),
            ChatMessage(
              message:
                  "Excellent! By escaping 'should' traps, you can reduce unnecessary pressure and treat yourself kindly.",
              isUser: false,
              options: ["I understand"],
            ),
            ChatMessage(
              message:
                  "You’ve completed the 'Escaping Should Traps' exercise. Remember to replace 'should' with realistic, supportive thoughts.",
              isUser: false,
              options: ["Done"],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color.fromARGB(255, 10, 10, 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exercises',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 10, 10, 10),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return ExerciseCategoryCard(
                      category: categories[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExerciseListScreen(category: categories[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseCategory {
  final String name;
  final String imagePath;
  final List<Exercise> exercises;

  ExerciseCategory({
    required this.name,
    required this.imagePath,
    required this.exercises,
  });
}

class Exercise {
  final String name;
  final String duration;
  final List<ChatMessage> chatFlow;

  Exercise({
    required this.name,
    required this.duration,
    required this.chatFlow,
  });
}

class ChatMessage {
  final String message;
  final bool isUser;
  final List<String> options;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.options,
  });
}

class ExerciseCategoryCard extends StatelessWidget {
  final ExerciseCategory category;
  final VoidCallback onTap;

  const ExerciseCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = category.imagePath.startsWith('http');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          image: DecorationImage(
            image: isNetworkImage
                ? NetworkImage(category.imagePath)
                : AssetImage(category.imagePath) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Material(
          color: const Color.fromARGB(0, 0, 0, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color.fromARGB(14, 0, 0, 0).withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseListScreen extends StatelessWidget {
  final ExerciseCategory category;

  const ExerciseListScreen({Key? key, required this.category})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color.fromARGB(255, 10, 10, 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 10, 10, 10),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: category.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = category.exercises[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.blue.shade700,
                          size: 30,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        exercise.duration,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExerciseChatScreen(exercise: exercise),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseChatScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseChatScreen({Key? key, required this.exercise})
    : super(key: key);

  @override
  State<ExerciseChatScreen> createState() => _ExerciseChatScreenState();
}

class _ExerciseChatScreenState extends State<ExerciseChatScreen> {
  final List<ChatMessage> _conversation = [];
  int _currentStep = 0;
  bool _exerciseCompleted = false;
  bool _userExited = false;
  // Controller to keep the chat scrolled to the latest message
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    if (widget.exercise.chatFlow.isNotEmpty) {
      _conversation.add(widget.exercise.chatFlow[0]);
      _currentStep = 1;

      // Add the first question with options
      if (_currentStep < widget.exercise.chatFlow.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _conversation.add(widget.exercise.chatFlow[_currentStep]);
          });
          // ensure the list scrolls to show the newly added message
          _scrollToEnd();
        });
      }
    }
  }

  void _onOptionSelected(String option) {
    // Add user's selected option to conversation
    setState(() {
      _conversation.add(
        ChatMessage(message: option, isUser: true, options: []),
      );
    });
    // after adding user message, scroll to bottom so it's visible
    _scrollToEnd();

    // Handle True/False logic
    if (option == "False") {
      // User wants to exit
      _handleExit();
    } else {
      // User wants to continue
      _handleContinue();
    }
  }

  void _handleContinue() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_currentStep < widget.exercise.chatFlow.length - 1) {
        setState(() {
          _currentStep++;
          _conversation.add(widget.exercise.chatFlow[_currentStep]);
        });
        // show the newly added guide message
        _scrollToEnd();
      } else {
        // Exercise completed
        setState(() {
          _exerciseCompleted = true;
          _conversation.add(
            ChatMessage(
              message:
                  "🎉 Congratulations! You've completed the exercise!\n\nYou've taken an important step toward your personal growth. Remember, consistency is key to building lasting confidence.",
              isUser: false,
              options: [],
            ),
          );
        });
        _scrollToEnd();

        // Option to go back after completion
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  void _handleExit() {
    setState(() {
      _userExited = true;
      _conversation.add(
        ChatMessage(
          message:
              "I understand. Sometimes it's not the right time, and that's okay. 🫂\n\nRemember, self-care means listening to your needs. You can always return to this exercise when you feel ready.",
          isUser: false,
          options: [],
        ),
      );
    });

    // ensure the exit message is visible
    _scrollToEnd();

    // Navigate back after exit message
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  // scroll helper — call after adding messages to show latest content
  void _scrollToEnd({Duration duration = const Duration(milliseconds: 300)}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasOptions =
        _conversation.isNotEmpty &&
        _conversation.last.options.isNotEmpty &&
        !_exerciseCompleted &&
        !_userExited;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header with exercise info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.exercise.duration,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.psychology, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 4),
                Text(
                  'CBT Exercise',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final message = _conversation[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Options from the current message (only show if exercise is still active)
          if (hasOptions) _buildOptions(_conversation.last.options),

          // Show status message when completed or exited
          if (_exerciseCompleted || _userExited)
            Container(
              padding: const EdgeInsets.all(16),
              color: _exerciseCompleted
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _exerciseCompleted
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: _exerciseCompleted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _exerciseCompleted
                        ? 'Exercise Completed'
                        : 'Exercise Paused',
                    style: TextStyle(
                      color: _exerciseCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: Colors.blue.shade700,
                size: 18,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.blue.shade500
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.isUser ? 'You' : 'Guide',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, color: Colors.green.shade700, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildOptions(List<String> options) {
    // OPTIONS: Centered and vertically-adjustable options block.
    // How to manage:
    //  - Change `verticalOffset` to move the options up/down (negative = up).
    //  - The Wrap is centered so any number of options (including single labels
    //    like "Remove") will display nicely.
    final double verticalOffset = -18.0; // <- tweak this value to move options

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 16, 137, 158),
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // If you'd like a prompt above the options, uncomment below and
            // pass the desired promptText in place of a hardcoded string.
            // Text('Would you like to continue?', style: ...),
            // const SizedBox(height: 8),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: options.map((opt) {
                  return SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _onOptionSelected(opt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        opt,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
