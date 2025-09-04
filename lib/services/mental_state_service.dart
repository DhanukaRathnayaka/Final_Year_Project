import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MentalStateService {
  static const String _groqApiKey = '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';
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> mentalConditions = [
    "happy/positive",
    "stressed/anxious",
    "depressed/sad",
    "angry/frustrated",
    "neutral/calm",
    "confused/uncertain",
    "excited/energetic"
  ];

  // Enhanced keywords for each mental state
  static const Map<String, List<String>> stateKeywords = {
    "happy/positive": [
      "happy", "joy", "excited", "great", "amazing", "wonderful", "fantastic",
      "love", "blessed", "grateful", "awesome", "perfect", "brilliant", "excellent",
      "thrilled", "delighted", "cheerful", "optimistic", "content", "satisfied",
      "yay", "yippee", "woohoo", "smile", "laugh", "good", "nice", "fun", "enjoy",
      "beautiful", "best", "better", "improving", "progress", "success", "win", "wonderful"
    ],
    "stressed/anxious": [
      "stressed", "anxious", "worried", "nervous", "panic", "overwhelmed",
      "pressure", "tense", "restless", "uneasy", "concerned", "frightened",
      "scared", "afraid", "terrified", "anxiety", "worry", "tension", "stress",
      "can't cope", "too much", "drowning", "buried", "deadline", "exam", "test",
      "interview", "nervous", "shaking", "heart racing", "panic attack", "freaking out"
    ],
    "depressed/sad": [
      "sad", "depressed", "down", "low", "empty", "hopeless", "lonely",
      "miserable", "devastated", "heartbroken", "disappointed", "gloomy",
      "melancholy", "despair", "grief", "sorrow", "blue", "unhappy", "tears",
      "crying", "alone", "isolated", "numb", "tired", "exhausted", "can't get up",
      "don't care", "pointless", "meaningless", "why bother", "end it", "give up"
    ],
    "angry/frustrated": [
      "angry", "mad", "furious", "frustrated", "annoyed", "irritated",
      "rage", "hate", "disgusted", "outraged", "livid", "pissed", "upset",
      "aggravated", "infuriated", "resentful", "bitter", "hostile", "sick of",
      "fed up", "had enough", "bullshit", "screw", "damn", "hell", "shit",
      "fuck", "hate", "loathe", "despise", "rage", "fuming", "seething"
    ],
    "confused/uncertain": [
      "confused", "uncertain", "lost", "puzzled", "bewildered", "perplexed",
      "unsure", "doubtful", "questioning", "unclear", "mixed up", "baffled",
      "don't know", "not sure", "maybe", "perhaps", "wondering", "undecided",
      "torn", "conflicted", "what if", "should I", "could I", "might", "possibly",
      "maybe", "hesitant", "second guess", "overthink", "analysis paralysis"
    ],
    "excited/energetic": [
      "excited", "energetic", "pumped", "hyped", "enthusiastic", "eager",
      "thrilled", "animated", "vibrant", "dynamic", "motivated", "inspire",
      "passionate", "fired up", "ready", "can't wait", "looking forward",
      "anticipating", "counting down", "thrilled", "ecstatic", "overjoyed",
      "elated", "jubilant", "exhilarated", "charged", "amped", "revved", "wired"
    ],
    "neutral/calm": [
      "ok", "okay", "fine", "alright", "good", "well", "decent", "average",
      "normal", "regular", "standard", "moderate", "balanced", "stable",
      "composed", "relaxed", "peaceful", "tranquil", "serene", "placid",
      "untroubled", "unworried", "unruffled", "collected", "cool", "level-headed"
    ]
  };

  // Common greetings and short phrases to filter out
  static const List<String> commonGreetings = [
    "hi", "hello", "hey", "good morning", "good afternoon", "good evening",
    "how are you", "what's up", "sup", "yo", "greetings", "hiya", "howdy",
    "good night", "bye", "goodbye", "see you", "take care", "thanks", "thank you"
  ];

  /// Preprocesses message to determine if it's suitable for analysis
  bool isMessageSuitableForAnalysis(String message) {
    final cleanMessage = message.toLowerCase().trim();
    
    // Only skip completely empty messages
    if (cleanMessage.isEmpty) return false;
    
    // Analyze everything else, including short messages and greetings
    return true;
  }

  /// Enhanced keyword-based analysis with better detection
  Map<String, dynamic> keywordBasedAnalysis(String message) {
    final cleanMessage = message.toLowerCase();
    final scores = <String, double>{};
    
    // Special handling for punctuation and capitalization
    final hasExclamation = cleanMessage.contains('!');
    final hasQuestion = cleanMessage.contains('?');
    final hasEllipsis = cleanMessage.contains('...');
    final hasAllCaps = message.toUpperCase() == message && message.length > 3;
    
    // Enhanced analysis for very short messages
    if (cleanMessage.length <= 5) {
      // Exclamation indicates excitement or strong emotion
      if (hasExclamation) {
        if (cleanMessage.contains('no') || cleanMessage.contains('stop')) {
          return {'prediction': 'angry/frustrated', 'confidence': 0.8};
        }
        return {'prediction': 'excited/energetic', 'confidence': 0.8};
      }
      
      // Question mark indicates uncertainty
      if (hasQuestion) {
        return {'prediction': 'confused/uncertain', 'confidence': 0.75};
      }
      
      // Ellipsis indicates hesitation or sadness
      if (hasEllipsis) {
        return {'prediction': 'depressed/sad', 'confidence': 0.7};
      }
      
      // All caps indicates strong emotion (anger or excitement)
      if (hasAllCaps) {
        if (cleanMessage.contains('yes') || cleanMessage.contains('go')) {
          return {'prediction': 'excited/energetic', 'confidence': 0.8};
        }
        return {'prediction': 'angry/frustrated', 'confidence': 0.8};
      }
      
      // Specific short responses
      if (cleanMessage == 'no' || cleanMessage == 'nah' || cleanMessage == 'nope') {
        return {'prediction': 'angry/frustrated', 'confidence': 0.7};
      }
      
      if (cleanMessage == 'yes' || cleanMessage == 'yeah' || cleanMessage == 'yep') {
        return {'prediction': 'happy/positive', 'confidence': 0.7};
      }
    }
    
    // Enhanced greeting analysis with emotional tone detection
    for (final greeting in commonGreetings) {
      if (cleanMessage.contains(greeting)) {
        // Analyze the tone of greetings
        if (hasExclamation || cleanMessage.contains('great') || cleanMessage.contains('good')) {
          return {'prediction': 'happy/positive', 'confidence': 0.8};
        }
        if (hasQuestion || cleanMessage.contains('how are you')) {
          return {'prediction': 'confused/uncertain', 'confidence': 0.7};
        }
        if (hasEllipsis || cleanMessage.contains('tired') || cleanMessage.contains('exhausted')) {
          return {'prediction': 'depressed/sad', 'confidence': 0.7};
        }
        // Default greeting sentiment
        return {'prediction': 'neutral/calm', 'confidence': 0.8};
      }
    }
    
    // Standard keyword analysis for longer messages
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
      
      // Adjust for punctuation and capitalization
      if (hasExclamation && (state == "excited/energetic" || state == "angry/frustrated")) {
        score += 1.0;
      }
      
      if (hasQuestion && state == "confused/uncertain") {
        score += 1.0;
      }
      
      if (hasEllipsis && (state == "depressed/sad" || state == "confused/uncertain")) {
        score += 1.0;
      }
      
      if (hasAllCaps && (state == "angry/frustrated" || state == "excited/energetic")) {
        score += 1.5;
      }
      
      // Adjust normalization for shorter messages
      final normalizer = cleanMessage.length < 20 ? keywords.length * 0.05 : keywords.length * 0.1;
      scores[state] = score / normalizer;
    }
    
    // Find the state with highest score
    if (scores.isNotEmpty) {
      final maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      // Lower threshold for short messages, higher for neutral/calm
      final threshold = maxEntry.key == "neutral/calm" ? 0.5 : 0.3;
      
      if (maxEntry.value > threshold) {
        return {
          'prediction': maxEntry.key,
          'confidence': (maxEntry.value * 0.15 + 0.7).clamp(0.7, 0.95)
        };
      }
    }
    
    // Default to confused/uncertain instead of neutral/calm to avoid bias
    return {'prediction': 'confused/uncertain', 'confidence': 0.6};
  }

  Future<Map<String, dynamic>> predict(String message) async {
    // Preprocess message - now analyzes ALL messages
    if (!isMessageSuitableForAnalysis(message)) {
      return {'prediction': 'neutral/calm', 'confidence': 0.6};
    }

    final enhancedPrompt = """
You are an expert mental health analyst. Analyze the following message and classify the writer's emotional/mental state.

CRITICAL INSTRUCTION: DO NOT DEFAULT TO NEUTRAL/CALM UNLESS THERE IS GENUINELY NO EMOTIONAL CONTENT.

IMPORTANT GUIDELINES:
1. Analyze ALL messages, including short ones, greetings, and single words
2. Even brief messages like "hi", "ok", "no" can convey emotional tone
3. Look for subtle emotional indicators in tone, punctuation, and word choice
4. Consider context clues like exclamation marks, question marks, capitalization
5. Every message has some emotional undertone - find it
6. BE BOLD in your classifications - avoid the safe "neutral/calm" option

CLASSIFICATION OPTIONS (choose exactly one):
${mentalConditions.map((condition) => '- $condition').join('\n')}

ANALYSIS GUIDELINES:
- "happy/positive": Joy, satisfaction, optimism, gratitude, excitement, enthusiastic greetings
- "stressed/anxious": Worry, pressure, nervousness, overwhelm, uncertain questions
- "depressed/sad": Sadness, hopelessness, emptiness, grief, flat/monotone responses
- "angry/frustrated": Anger, irritation, rage, resentment, short/abrupt responses
- "neutral/calm": ONLY for genuinely balanced, peaceful, matter-of-fact content
- "confused/uncertain": Doubt, bewilderment, indecision, questioning tone, hesitation
- "excited/energetic": High energy, enthusiasm, anticipation, exclamation marks, caps

PUNCTUATION ANALYSIS:
- "!" → excited/energetic or angry/frustrated
- "?" → confused/uncertain 
- "..." → depressed/sad or confused/uncertain
- ALL CAPS → angry/frustrated or excited/energetic

EXAMPLES:
- "hi!" → excited/energetic (enthusiastic greeting)
- "hi" → neutral/calm (simple greeting)
- "ok..." → depressed/sad (hesitant, down)
- "OK" → neutral/calm (acknowledgment)
- "no" → angry/frustrated (negative response)
- "NO!" → angry/frustrated (emphatic rejection)
- "yes!" → excited/energetic (enthusiastic agreement)
- "what?" → confused/uncertain (questioning)
- "I can't do this..." → depressed/sad (giving up)
- "I'M SO ANGRY" → angry/frustrated (all caps emphasis)

MESSAGE TO ANALYZE: "$message"

Provide your response in this exact JSON format:
{
    "prediction": "exact_condition_from_list",
    "confidence": 0.85,
    "reasoning": "brief explanation of why you chose this classification, including punctuation analysis"
}

Confidence should be between 0.7-1.0. Even for short messages, provide confident analysis.
""";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert mental health analyst specializing in emotional state classification from text. BE BOLD in your classifications and avoid defaulting to neutral/calm.'
            },
            {'role': 'user', 'content': enhancedPrompt}
          ],
          'temperature': 0.9, // Higher temperature for more diverse responses
          'max_tokens': 200,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content);
        
        // Validate the prediction is in our allowed list
        final prediction = result['prediction']?.toString() ?? '';
        if (!mentalConditions.contains(prediction)) {
          print('Invalid prediction received: $prediction, using keyword analysis');
          return keywordBasedAnalysis(message);
        }
        
        // If AI returns neutral/calm, double-check with keyword analysis
        if (prediction == 'neutral/calm') {
          final keywordResult = keywordBasedAnalysis(message);
          // Only use neutral/calm if keyword analysis also suggests it with high confidence
          if (keywordResult['prediction'] != 'neutral/calm' ||
              keywordResult['confidence'] < 0.8) {
            print('Overriding neutral/calm with keyword analysis: ${keywordResult['prediction']}');
            return keywordResult;
          }
        }
        
        return {
          'prediction': prediction,
          'confidence': (result['confidence'] ?? 0.7).toDouble().clamp(0.7, 1.0),
          'reasoning': result['reasoning'] ?? 'AI analysis'
        };
      } else {
        print('Groq API error: ${response.statusCode} - ${response.body}');
        return keywordBasedAnalysis(message);
      }
    } catch (e) {
      print('Prediction error: $e');
      // Use keyword-based analysis as fallback
      return keywordBasedAnalysis(message);
    }
  }

  Future<void> analyzeUserMentalState(String userId) async {
    try {
      // Get user messages from Supabase, ordered by creation time
      final messages = await _supabase
          .from('messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      
      if (messages.isEmpty) {
        print('No messages found for user $userId');
        return;
      }

      // Now analyze ALL messages since users don't chat much
      final suitableMessages = messages
          .where((msg) => isMessageSuitableForAnalysis(msg['message']))
          .toList();

      if (suitableMessages.length < 1) {
        print('No messages found for analysis');
        return;
      }

      final stateCounts = <String, int>{};
      final stateConfidences = <String, List<double>>{};
      var totalConfidence = 0.0;
      var analyzedCount = 0;

      // Take recent messages for analysis (last 30 suitable messages)
      final recentMessages = suitableMessages.length > 30
          ? suitableMessages.sublist(suitableMessages.length - 30)
          : suitableMessages;

      print('Analyzing ${recentMessages.length} messages for user $userId');

      // Analyze individual messages with context
      for (int i = 0; i < recentMessages.length; i++) {
        final msg = recentMessages[i];
        final result = await predict(msg['message']);
        
        final prediction = result['prediction'];
        final confidence = result['confidence'];
        
        // Only count predictions with reasonable confidence
        if (confidence >= 0.7) {
          stateCounts.update(
            prediction,
            (value) => value + 1,
            ifAbsent: () => 1
          );
          
          stateConfidences.update(
            prediction,
            (list) => list..add(confidence),
            ifAbsent: () => [confidence]
          );
          
          totalConfidence += confidence;
          analyzedCount++;
        }

        // Add small delay to avoid rate limiting
        if (i < recentMessages.length - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      if (analyzedCount == 0) {
        print('No confident predictions made for user $userId');
        return;
      }

      // Calculate weighted scores for each state
      final stateScores = <String, double>{};
      for (final state in stateCounts.keys) {
        final count = stateCounts[state]!;
        final confidences = stateConfidences[state]!;
        final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;
        
        // Weight by both frequency and confidence
        stateScores[state] = (count / analyzedCount) * avgConfidence;
      }

      // Find dominant state
      final dominantStateEntry = stateScores.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      final avgConfidence = totalConfidence / analyzedCount;
      final dominantStatePercentage = dominantStateEntry.value;

      // Always select the most dominant state, never return mixed/no_clear_pattern
      String finalState = dominantStateEntry.key;
      
      // Only default to neutral/calm if there's genuinely no clear pattern and very low confidence
      if (dominantStatePercentage < 0.15 && avgConfidence < 0.7) {
        // Instead of neutral/calm, use the most frequent state even if confidence is low
        finalState = dominantStateEntry.key;
      }

      // Calculate trend analysis (comparing first half vs second half)
      String trend = 'stable';
      if (recentMessages.length >= 10) {
        final firstHalf = recentMessages.sublist(0, recentMessages.length ~/ 2);
        final secondHalf = recentMessages.sublist(recentMessages.length ~/ 2);
        
        // This is a simplified trend analysis - could be enhanced further
        final firstHalfNegative = await _countNegativeStates(firstHalf);
        final secondHalfNegative = await _countNegativeStates(secondHalf);
        
        if (secondHalfNegative > firstHalfNegative + 1) {
          trend = 'declining';
        } else if (firstHalfNegative > secondHalfNegative + 1) {
          trend = 'improving';
        }
      }

      // Create comprehensive report
      final report = {
        'user_id': userId,
        'analysis_timestamp': DateTime.now().toIso8601String(),
        'total_messages_found': messages.length,
        'suitable_messages_analyzed': analyzedCount,
        'dominant_state': finalState,
        'confidence': avgConfidence,
        'dominant_state_percentage': dominantStatePercentage,
        'trend': trend,
        'state_distribution': stateCounts,
        'state_scores': stateScores,
        'analysis_period_days': _calculateAnalysisPeriod(recentMessages),
        'analysis_quality': dominantStatePercentage > 0.4 ? 'high' :
                           dominantStatePercentage > 0.25 ? 'medium' : 'low'
      };

      // Save report to Supabase
      await _supabase
          .from('mental_state_reports')
          .insert({
            'user_id': userId,
            'report': jsonEncode(report),
            'dominant_state': finalState,
            'confidence': avgConfidence,
            'created_at': DateTime.now().toIso8601String(),
          });

      print('✅ Mental state analysis completed for user $userId');
      print('   Dominant state: $finalState (${(dominantStatePercentage * 100).toStringAsFixed(1)}%)');
      print('   Confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
      print('   Trend: $trend');

    } catch (e) {
      print('Error in mental state analysis: $e');
      rethrow; // Re-throw to allow caller to handle
    }
  }

  /// Helper method to count negative mental states
  Future<int> _countNegativeStates(List<dynamic> messages) async {
    int count = 0;
    final negativeStates = ['stressed/anxious', 'depressed/sad', 'angry/frustrated'];
    
    for (final msg in messages) {
      if (isMessageSuitableForAnalysis(msg['message'])) {
        final result = await predict(msg['message']);
        if (negativeStates.contains(result['prediction']) && result['confidence'] >= 0.7) {
          count++;
        }
      }
    }
    return count;
  }

  /// Calculate the time period covered by the analysis
  int _calculateAnalysisPeriod(List<dynamic> messages) {
    if (messages.length < 2) return 0;
    
    try {
      final firstMessage = DateTime.parse(messages.first['created_at']);
      final lastMessage = DateTime.parse(messages.last['created_at']);
      return lastMessage.difference(firstMessage).inDays;
    } catch (e) {
      return 0;
    }
  }

  // Check if user has enough messages to analyze
  Future<bool> hasEnoughMessages(String userId) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select()
          .eq('user_id', userId);

      // Check for suitable messages, not just total count
      final suitableMessages = messages
          .where((msg) => isMessageSuitableForAnalysis(msg['message']))
          .toList();

      return suitableMessages.length >= 1; // Minimum 1 message (since we analyze everything now)
    } catch (e) {
      return false;
    }
  }

  /// Get a quick mental state prediction for a single message (for real-time use)
  /// Now analyzes ALL messages including short ones and greetings
  Future<Map<String, dynamic>> getQuickPrediction(String message) async {
    if (!isMessageSuitableForAnalysis(message)) {
      return {
        'prediction': 'neutral/calm',
        'confidence': 0.6,
        'reasoning': 'Empty message'
      };
    }

    // For quick predictions, use keyword analysis first
    final keywordResult = keywordBasedAnalysis(message);
    
    // If keyword analysis is confident enough, return it
    if (keywordResult['confidence'] >= 0.75) {
      return keywordResult;
    }

    // Otherwise, use AI prediction
    return await predict(message);
  }

  /// Batch analyze multiple messages efficiently
  Future<List<Map<String, dynamic>>> batchPredict(List<String> messages) async {
    final results = <Map<String, dynamic>>[];
    
    for (int i = 0; i < messages.length; i++) {
      final result = await predict(messages[i]);
      results.add(result);
      
      // Add delay to avoid rate limiting
      if (i < messages.length - 1) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }
    
    return results;
  }
}