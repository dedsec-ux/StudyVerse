import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey = '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';
  
  // Task-optimized free models - prioritizing SPEED with QUALITY
  static const Map<String, String> _taskOptimizedModels = {
    'reasoning': 'deepseek/deepseek-r1-0528-qwen3-8b:free',  // 8B params but R1 reasoning - FAST!
    'content': 'qwen/qwen3-30b-a3b:free',                    // MoE: only 3.3B active - FAST!
    'general': 'qwen/qwen3-14b:free',                        // 14.8B params - FAST & efficient
    'quick': 'qwen/qwen3-4b:free',                           // 4B params - VERY FAST
  };
  
  // Fast and reliable fallback models
  static const List<String> _fallbackModels = [
    'qwen/qwq-32b:free',                                     // 32B but optimized for speed
    'qwen/qwen3-14b:free',                                   // 14.8B params - reliable
    'qwen/qwen3-4b:free',                                    // 4B params - backup
    'deepseek/deepseek-r1:free',                             // 671B - last resort (slower)
  ];
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
    'HTTP-Referer': 'https://studyverse.devauralab.com', // Replace with your app URL
    'X-Title': 'StudyVerse AI Toolkit',
  };

  // Smart Summary API Call
  static Future<String> generateSummary({
    required String text,
    bool explainLikeChild = false,
  }) async {
    try {
      final prompt = explainLikeChild 
        ? '''
Please summarize the following text in a very simple way that a 10-year-old could understand. Use bullet points and simple language:

Text: $text

Format your response as clean bullet points that explain the main ideas simply.
'''
        : '''
Please create a clean, bullet-point summary of the following text. Focus on the key points and main ideas:

Text: $text

Format your response as organized bullet points that capture the essential information.
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'quick');
      return response ?? 'Failed to generate summary. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate summary: ${e.toString()}');
      return 'Error occurred while generating summary.';
    }
  }

  // Quiz Maker API Call
  static Future<String> generateQuiz({
    required String topic,
    required int questionCount,
    required String questionType,
  }) async {
    try {
      final prompt = '''
Create $questionCount $questionType questions about: $topic

Format requirements:
- If Multiple Choice: Provide 4 options (A, B, C, D) with the correct answer marked
- If True/False: Provide clear statements with correct answers
- If Fill in the Blanks: Provide sentences with blanks and the correct answers
- Include an answer key at the end

Make the questions educational and appropriately challenging.
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'content');
      return response ?? 'Failed to generate quiz. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate quiz: ${e.toString()}');
      return 'Error occurred while generating quiz.';
    }
  }

  // Concept Explainer API Call
  static Future<String> explainConcept({
    required String concept,
    required String difficultyLevel,
    String? secondConcept,
  }) async {
    try {
      String prompt;
      
      if (secondConcept != null && secondConcept.isNotEmpty) {
        // Comparison mode
        prompt = '''
Compare and contrast these two concepts: "$concept" and "$secondConcept"

Please provide:
1. Similarities between them
2. Key differences
3. When to use each one
4. Real-world examples for both

Format your response clearly with headings and bullet points.
''';
      } else {
        // Single concept explanation
        switch (difficultyLevel.toLowerCase()) {
          case 'simple':
            prompt = '''
Explain "$concept" in very simple terms that anyone can understand. Use analogies and everyday examples.

Structure your explanation:
- What it is (in simple terms)
- Why it matters
- Real-world examples
- Simple analogy to help remember it

Keep the language conversational and easy to understand.
''';
            break;
          case 'intermediate':
            prompt = '''
Provide an intermediate-level explanation of "$concept".

Include:
- Core principles and key components
- How it works in practice
- Applications and use cases
- Relationships to other concepts
- Why it's important to understand

Use clear structure with headings and examples.
''';
            break;
          case 'advanced':
            prompt = '''
Provide an advanced, comprehensive analysis of "$concept".

Cover:
- Theoretical foundations and principles
- Technical details and mechanisms
- Current research and developments
- Limitations and considerations
- Advanced applications and implications
- Connection to broader frameworks

Use academic-level depth while maintaining clarity.
''';
            break;
          default:
            prompt = 'Explain "$concept" clearly with examples and practical applications.';
        }
      }

      final response = await _makeTaskOptimizedApiCall(prompt, 'content');
      return response ?? 'Failed to explain concept. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to explain concept: ${e.toString()}');
      return 'Error occurred while explaining concept.';
    }
  }

  // Assignment Helper API Call
  static Future<String> helpWithAssignment({
    required String topic,
    required String assignmentType,
    required String tone,
    String? additionalRequirements,
  }) async {
    try {
      final requirements = additionalRequirements?.isNotEmpty == true 
        ? '\n\nAdditional requirements: $additionalRequirements' 
        : '';
      
      final prompt = '''
Help create a $assignmentType about "$topic" with a $tone tone.

Please provide:
1. A clear structure/outline
2. Key points to cover
3. Supporting arguments or evidence
4. A strong introduction approach
5. A compelling conclusion strategy

$requirements

Format the response with clear headings and bullet points for easy reading.
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'reasoning');
      return response ?? 'Failed to generate assignment help. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate assignment help: ${e.toString()}');
      return 'Error occurred while generating assignment help.';
    }
  }

  // Study Planner API Call
  static Future<String> createStudyPlan({
    required String subject,
    required int studyHours,
    required String timeframe,
    String? goals,
  }) async {
    try {
      final goalText = goals?.isNotEmpty == true ? '\nSpecific goals: $goals' : '';
      
      final prompt = '''
Create a personalized study plan for: $subject

Study parameters:
- Available study hours per day: $studyHours hours
- Timeframe: $timeframe
$goalText

Please provide:
1. A day-by-day schedule breakdown
2. Specific topics to cover each day
3. Recommended study techniques
4. Progress milestones
5. Review and practice sessions
6. Tips for staying motivated

Format as a clear, actionable schedule with daily tasks.
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'reasoning');
      return response ?? 'Failed to create study plan. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to create study plan: ${e.toString()}');
      return 'Error occurred while creating study plan.';
    }
  }

  // Flashcard Generator API Call
  static Future<String> generateFlashcards({
    required String topic,
    required int cardCount,
  }) async {
    try {
      final prompt = '''
Create $cardCount educational flashcards about: $topic

Format EXACTLY as shown below (this is critical):

**Card 1:**
**Front:** What is the main concept of $topic?
**Back:** Clear, concise explanation of the main concept

**Card 2:**
**Front:** Why is $topic important?
**Back:** Explain the significance and benefits

**Card 3:**
**Front:** How is $topic applied in real life?
**Back:** Practical applications and examples

**Card 4:**
**Front:** What are the key components of $topic?
**Back:** List and explain the main elements

**Card 5:**
**Front:** What should students remember about $topic?
**Back:** Key takeaways and important points

**Card 6:**
**Front:** How does $topic relate to other concepts?
**Back:** Connections and relationships

Make sure each card:
- Has a clear question on the front
- Has a concise, educational answer on the back
- Is factually accurate and educational
- Uses simple, clear language
- Follows the EXACT format shown above
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'content');
      return response ?? 'Failed to generate flashcards. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate flashcards: ${e.toString()}');
      return 'Error occurred while generating flashcards.';
    }
  }

  // Debate Builder API Call
  static Future<String> buildDebateArguments({
    required String topic,
    required String position,
  }) async {
    try {
      final prompt = '''
Build strong debate arguments for the $position side of: "$topic"

Provide:
1. **Opening Statement:** A compelling introduction to your position
2. **Main Arguments:** 3-4 strong points supporting your position
3. **Evidence & Examples:** Supporting facts, statistics, or examples
4. **Counter-argument Responses:** How to address opposing viewpoints
5. **Closing Statement:** A powerful conclusion that reinforces your position

Format with clear headings and bullet points for easy reference during a debate.
''';

      final response = await _makeTaskOptimizedApiCall(prompt, 'reasoning');
      return response ?? 'Failed to build debate arguments. Please try again.';
    } catch (e) {
      Get.snackbar('Error', 'Failed to build debate arguments: ${e.toString()}');
      return 'Error occurred while building debate arguments.';
    }
  }

  // Private method to make task-optimized API calls
  static Future<String?> _makeTaskOptimizedApiCall(String prompt, String taskType) async {
    // Get the best model for this task type
    String primaryModel = _taskOptimizedModels[taskType] ?? _taskOptimizedModels['general']!;
    List<String> modelsToTry = [primaryModel, ..._fallbackModels];
    
    for (String model in modelsToTry) {
      try {
        final requestBody = {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': taskType == 'reasoning' ? 1500 : (taskType == 'quick' ? 1000 : 1200), // Optimized for speed
          'temperature': taskType == 'reasoning' ? 0.4 : (taskType == 'quick' ? 0.5 : 0.6),   // Balanced for speed & quality
        };

        final response = await http.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: _headers,
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final content = data['choices']?[0]?['message']?['content'];
          return content?.toString().trim();
        } else if (response.statusCode == 429) {
          Get.snackbar('Rate Limit', 'Too many requests. Please wait a moment and try again.');
          return null;
        } else if (response.statusCode == 401) {
          Get.snackbar('API Error', 'Invalid API key. Please check your configuration.');
          return null;
        } else if (response.statusCode == 404 && model != modelsToTry.last) {
          // Model not available, try next one
          continue;
        } else {
          Get.snackbar('API Error', 'Failed to get response from AI service. Status: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        if (model == modelsToTry.last) {
          throw Exception('Network error: ${e.toString()}');
        }
        // Try next model
        continue;
      }
    }
    
    return null;
  }

  // Private method to make API calls with fallback models (legacy method)
  static Future<String?> _makeApiCall(String prompt) async {
    return _makeTaskOptimizedApiCall(prompt, 'general');
  }

  // Check if API key is configured
  static bool isApiKeyConfigured() {
    return _apiKey != 'YOUR_OPENROUTER_API_KEY' && _apiKey.isNotEmpty;
  }

  // Get available free models (this could be expanded to fetch from API)
  static List<String> getAvailableFreeModels() {
    return [..._taskOptimizedModels.values, ..._fallbackModels];
  }
} 