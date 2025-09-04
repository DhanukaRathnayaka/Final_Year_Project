import 'package:flutter_test/flutter_test.dart';

// Test-specific service that doesn't initialize Supabase
class TestMentalStateService {
  static const List<String> mentalConditions = [
    "happy/positive",
    "stressed/anxious",
    "depressed/sad",
    "angry/frustrated",
    "neutral/calm",
    "confused/uncertain",
    "excited/energetic"
  ];

  // Keywords for each mental state to help with classification
  static const Map<String, List<String>> stateKeywords = {
    "happy/positive": [
      "happy", "joy", "excited", "great", "amazing", "wonderful", "fantastic",
      "love", "blessed", "grateful", "awesome", "perfect", "brilliant", "excellent",
      "thrilled", "delighted", "cheerful", "optimistic", "content", "satisfied"
    ],
    "stressed/anxious": [
      "stressed", "anxious", "worried", "nervous", "panic", "overwhelmed",
      "pressure", "tense", "restless", "uneasy", "concerned", "frightened",
      "scared", "afraid", "terrified", "anxious", "worry", "tension", "stress"
    ],
    "depressed/sad": [
      "sad", "depressed", "down", "low", "empty", "hopeless", "lonely",
      "miserable", "devastated", "heartbroken", "disappointed", "gloomy",
      "melancholy", "despair", "grief", "sorrow", "blue", "unhappy"
    ],
    "angry/frustrated": [
      "angry", "mad", "furious", "frustrated", "annoyed", "irritated",
      "rage", "hate", "disgusted", "outraged", "livid", "pissed", "upset",
      "aggravated", "infuriated", "resentful", "bitter", "hostile"
    ],
    "confused/uncertain": [
      "confused", "uncertain", "lost", "puzzled", "bewildered", "perplexed",
      "unsure", "doubtful", "questioning", "unclear", "mixed up", "baffled",
      "don't know", "not sure", "maybe", "perhaps", "wondering"
    ],
    "excited/energetic": [
      "excited", "energetic", "pumped", "hyped", "enthusiastic", "eager",
      "thrilled", "animated", "vibrant", "dynamic", "motivated", "inspired",
      "passionate", "fired up", "ready", "can't wait"
    ]
  };

  // Common greetings and short phrases to filter out
  static const List<String> commonGreetings = [
    "hi", "hello", "hey", "good morning", "good afternoon", "good evening",
    "how are you", "what's up", "sup", "yo", "greetings", "hiya", "howdy",
    "good night", "bye", "goodbye", "see you", "take care", "thanks", "thank you",
    "ok", "okay", "yes", "no", "sure", "alright", "cool", "nice", "great"
  ];

  /// Preprocesses message to determine if it's suitable for analysis
  /// Now analyzes ALL messages as users don't chat much and every message is valuable
  bool isMessageSuitableForAnalysis(String message) {
    final cleanMessage = message.toLowerCase().trim();
    
    // Only skip completely empty messages
    if (cleanMessage.isEmpty) return false;
    
    // Analyze everything else, including short messages and greetings
    return true;
  }

  /// Performs keyword-based analysis as a fallback
  Map<String, dynamic> keywordBasedAnalysis(String message) {
    final cleanMessage = message.toLowerCase();
    final scores = <String, double>{};
    
    for (final state in stateKeywords.keys) {
      double score = 0.0;
      final keywords = stateKeywords[state]!;
      
      for (final keyword in keywords) {
        if (cleanMessage.contains(keyword)) {
          // Give higher weight to exact word matches
          if (RegExp(r'\b' + RegExp.escape(keyword) + r'\b').hasMatch(cleanMessage)) {
            score += 2.0;
          } else {
            score += 1.0;
          }
        }
      }
      
      // Normalize score based on message length and keyword count
      scores[state] = score / (keywords.length * 0.1);
    }
    
    // Find the state with highest score
    final maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (maxEntry.value > 0.5) {
      return {
        'prediction': maxEntry.key,
        'confidence': (maxEntry.value * 0.1 + 0.7).clamp(0.7, 0.95)
      };
    }
    
    return {'prediction': 'neutral/calm', 'confidence': 0.7};
  }
}

void main() {
  group('MentalStateService Tests', () {
    late TestMentalStateService service;

    setUp(() {
      service = TestMentalStateService();
    });

    test('should analyze all messages including short ones', () {
      // Test that ALL messages are now analyzed
      expect(service.isMessageSuitableForAnalysis('hi'), true);
      expect(service.isMessageSuitableForAnalysis('hello'), true);
      expect(service.isMessageSuitableForAnalysis('ok'), true);
      expect(service.isMessageSuitableForAnalysis('I am feeling really sad today and don\'t know what to do'), true);
    });

    test('should analyze common greetings and short phrases', () {
      expect(service.isMessageSuitableForAnalysis('good morning'), true);
      expect(service.isMessageSuitableForAnalysis('how are you'), true);
      expect(service.isMessageSuitableForAnalysis('thanks'), true);
      expect(service.isMessageSuitableForAnalysis('I had a wonderful day today, everything went perfectly'), true);
    });

    test('keyword analysis should work for different states', () {
      // Test happy/positive
      var result = service.keywordBasedAnalysis('I am so happy and excited about this amazing opportunity');
      expect(result['prediction'], 'happy/positive');
      expect(result['confidence'], greaterThan(0.7));

      // Test stressed/anxious
      result = service.keywordBasedAnalysis('I am so stressed and worried about the upcoming exam, feeling overwhelmed');
      expect(result['prediction'], 'stressed/anxious');
      expect(result['confidence'], greaterThan(0.7));

      // Test depressed/sad
      result = service.keywordBasedAnalysis('I feel so sad and hopeless, everything seems empty and meaningless');
      expect(result['prediction'], 'depressed/sad');
      expect(result['confidence'], greaterThan(0.7));

      // Test angry/frustrated
      result = service.keywordBasedAnalysis('I am so angry and frustrated with this situation, it makes me furious');
      expect(result['prediction'], 'angry/frustrated');
      expect(result['confidence'], greaterThan(0.7));
    });

    test('should return neutral for messages without clear emotional indicators', () {
      var result = service.keywordBasedAnalysis('The weather is nice today and I went to the store');
      expect(result['prediction'], 'neutral/calm');
    });

    test('should handle edge cases gracefully', () {
      // Empty message - only this should be filtered out
      expect(service.isMessageSuitableForAnalysis(''), false);
      
      // Everything else should be analyzed now
      expect(service.isMessageSuitableForAnalysis('!!!???'), true);
      expect(service.isMessageSuitableForAnalysis('123456'), true);
      expect(service.isMessageSuitableForAnalysis('123!@#abc'), true);
    });

    test('should always return valid mental state predictions', () {
      // Test that we never get mixed/no_clear_pattern
      var result = service.keywordBasedAnalysis('I was happy at first but now I feel devastated and hopeless about everything');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      expect(result['prediction'], isNot('mixed/no_clear_pattern'));
      
      // Excitement
      result = service.keywordBasedAnalysis('I am so pumped and energetic about this new project, can\'t wait to start');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      expect(result['prediction'], isNot('mixed/no_clear_pattern'));
      
      // Confusion
      result = service.keywordBasedAnalysis('I am so confused and uncertain about what to do, everything is unclear');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      expect(result['prediction'], isNot('mixed/no_clear_pattern'));
      
      // Test short messages and greetings
      result = service.keywordBasedAnalysis('hi!');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      expect(result['prediction'], isNot('mixed/no_clear_pattern'));
      
      result = service.keywordBasedAnalysis('ok');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      expect(result['prediction'], isNot('mixed/no_clear_pattern'));
    });
  });

  group('Mental State Keywords Tests', () {
    test('should have comprehensive keywords for each state', () {
      expect(TestMentalStateService.stateKeywords['happy/positive']!.length, greaterThan(15));
      expect(TestMentalStateService.stateKeywords['stressed/anxious']!.length, greaterThan(15));
      expect(TestMentalStateService.stateKeywords['depressed/sad']!.length, greaterThan(15));
      expect(TestMentalStateService.stateKeywords['angry/frustrated']!.length, greaterThan(15));
      expect(TestMentalStateService.stateKeywords['confused/uncertain']!.length, greaterThan(10));
      expect(TestMentalStateService.stateKeywords['excited/energetic']!.length, greaterThan(10));
    });

    test('should contain expected keywords', () {
      expect(TestMentalStateService.stateKeywords['happy/positive']!, contains('happy'));
      expect(TestMentalStateService.stateKeywords['happy/positive']!, contains('joy'));
      expect(TestMentalStateService.stateKeywords['stressed/anxious']!, contains('stressed'));
      expect(TestMentalStateService.stateKeywords['stressed/anxious']!, contains('anxious'));
      expect(TestMentalStateService.stateKeywords['depressed/sad']!, contains('sad'));
      expect(TestMentalStateService.stateKeywords['depressed/sad']!, contains('depressed'));
    });
  });

  group('Real-world Message Tests', () {
    late TestMentalStateService service;

    setUp(() {
      service = TestMentalStateService();
    });

    test('should correctly classify real-world messages', () {
      // Happy messages
      var result = service.keywordBasedAnalysis('Just got promoted at work! I am absolutely thrilled and grateful for this opportunity');
      expect(result['prediction'], 'happy/positive');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      
      // Stressed messages
      result = service.keywordBasedAnalysis('I have three exams tomorrow and I haven\'t studied enough. I\'m so stressed and anxious');
      expect(result['prediction'], 'stressed/anxious');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      
      // Sad messages
      result = service.keywordBasedAnalysis('My pet passed away yesterday. I feel so empty and heartbroken, nothing feels the same');
      expect(result['prediction'], 'depressed/sad');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
      
      // Angry messages
      result = service.keywordBasedAnalysis('The customer service was terrible! I am so frustrated and angry with their attitude');
      expect(result['prediction'], 'angry/frustrated');
      expect(TestMentalStateService.mentalConditions, contains(result['prediction']));
    });
  });
}