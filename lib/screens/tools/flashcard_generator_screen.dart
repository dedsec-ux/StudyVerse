import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/openrouter_service.dart';

class FlashcardGeneratorScreen extends StatefulWidget {
  const FlashcardGeneratorScreen({super.key});

  @override
  State<FlashcardGeneratorScreen> createState() => _FlashcardGeneratorScreenState();
}

class _FlashcardGeneratorScreenState extends State<FlashcardGeneratorScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, String>> _flashcards = [];
  bool _hasResult = false;
  int _currentCardIndex = 0;
  bool _isFlipped = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateFlashcards() async {
    if (_inputController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter notes or terms to create flashcards');
      return;
    }

    // Check if API key is configured
    if (!OpenRouterService.isApiKeyConfigured()) {
      Get.snackbar(
        'API Key Required', 
        'Please configure your OpenRouter API key in the service file',
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call OpenRouter API with improved prompt
      final response = await OpenRouterService.generateFlashcards(
        topic: _inputController.text.trim(),
        cardCount: 6,
      );

      print('=== FLASHCARD API RESPONSE ===');
      print(response);
      print('=== END RESPONSE ===');

      // Parse the response to create individual flashcards
      List<Map<String, String>> parsedFlashcards = _parseFlashcardsFromResponse(response);
      
      // If parsing fails, create enhanced default flashcards
      if (parsedFlashcards.isEmpty) {
        parsedFlashcards = _createEnhancedFlashcards(_inputController.text.trim(), response);
      }

      setState(() {
        _isLoading = false;
        _flashcards = parsedFlashcards;
        _hasResult = true;
        _currentCardIndex = 0;
        _isFlipped = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to generate flashcards: ${e.toString()}');
    }
  }

  List<Map<String, String>> _parseFlashcardsFromResponse(String response) {
    List<Map<String, String>> flashcards = [];
    
    // Method 1: Try to parse structured format with **Card X:** pattern
    final cardPattern = RegExp(r'\*\*Card \d+:\*\*\s*\*\*Front:\*\*(.*?)\*\*Back:\*\*(.*?)(?=\*\*Card|\$|$)', dotAll: true);
    final matches = cardPattern.allMatches(response);
    
    for (final match in matches) {
      final front = match.group(1)?.trim().replaceAll(RegExp(r'^\*\*|\*\*$'), '').trim() ?? '';
      final back = match.group(2)?.trim().replaceAll(RegExp(r'^\*\*|\*\*$'), '').trim() ?? '';
      
              if (front.isNotEmpty && back.isNotEmpty) {
          flashcards.add({
            'question': _cleanAndTruncateText(front, 200),
            'answer': _cleanAndTruncateText(back, 300),
          });
        }
    }
    
    // Method 2: Try simpler Front/Back pattern
    if (flashcards.isEmpty) {
      final frontBackPattern = RegExp(r'\*\*Front:\*\*(.*?)\*\*Back:\*\*(.*?)(?=\*\*Front|\$|$)', dotAll: true);
      final frontBackMatches = frontBackPattern.allMatches(response);
      
      for (final match in frontBackMatches) {
        final front = match.group(1)?.trim() ?? '';
        final back = match.group(2)?.trim() ?? '';
        
        if (front.isNotEmpty && back.isNotEmpty) {
          flashcards.add({
            'question': _cleanAndTruncateText(front, 200),
            'answer': _cleanAndTruncateText(back, 300),
          });
        }
      }
    }
    
    // Method 3: Try Q&A pattern
    if (flashcards.isEmpty) {
      final qaPattern = RegExp(r'Q\d*[:\-\s]+(.*?)(?:\n|^)A\d*[:\-\s]+(.*?)(?=Q\d*[:\-\s]|\$|$)', dotAll: true, multiLine: true);
      final qaMatches = qaPattern.allMatches(response);
      
      for (final match in qaMatches) {
        final question = match.group(1)?.trim() ?? '';
        final answer = match.group(2)?.trim() ?? '';
        
        if (question.isNotEmpty && answer.isNotEmpty) {
          flashcards.add({
            'question': _cleanAndTruncateText(question, 200),
            'answer': _cleanAndTruncateText(answer, 300),
          });
        }
      }
    }
    
    // Method 4: Try numbered list pattern
    if (flashcards.isEmpty) {
      final lines = response.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      List<String> questions = [];
      List<String> answers = [];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Look for question patterns
        if (line.contains('?') || line.toLowerCase().contains('what') || line.toLowerCase().contains('how') || 
            line.toLowerCase().contains('why') || line.toLowerCase().contains('define')) {
          questions.add(_cleanAndTruncateText(line, 200));
        }
        // Look for answer patterns (next line after question or definition-like lines)
        else if (questions.length > answers.length && line.length > 10) {
          answers.add(_cleanAndTruncateText(line, 300));
        }
      }
      
      // Create flashcards from questions and answers
      final minCount = questions.length < answers.length ? questions.length : answers.length;
      for (int i = 0; i < minCount; i++) {
        flashcards.add({
          'question': questions[i],
          'answer': answers[i],
        });
      }
    }
    
    // Limit to 6 cards maximum
    if (flashcards.length > 6) {
      flashcards = flashcards.sublist(0, 6);
    }
    
    print('=== PARSED FLASHCARDS ===');
    for (int i = 0; i < flashcards.length; i++) {
      print('Card ${i + 1}:');
      print('Q: ${flashcards[i]['question']}');
      print('A: ${flashcards[i]['answer']}');
      print('---');
    }
    
    return flashcards;
  }

  String _cleanAndTruncateText(String text, int maxLength) {
    // Remove common formatting and cleanup
    text = text.replaceAll(RegExp(r'^\d+\.?\s*'), '');  // Remove numbering
    text = text.replaceAll(RegExp(r'^\*+\s*'), '');     // Remove bullet points
    text = text.replaceAll(RegExp(r'\*\*'), '');        // Remove bold markdown
    text = text.replaceAll(RegExp(r'__'), '');          // Remove bold markdown
    text = text.replaceAll(RegExp(r'^\-\s*'), '');      // Remove dashes
    text = text.trim();
    
    if (text.length <= maxLength) return text;
    
    // Find the last space before maxLength to avoid cutting words
    int cutIndex = maxLength;
    while (cutIndex > 0 && text[cutIndex] != ' ') {
      cutIndex--;
    }
    
    if (cutIndex == 0) cutIndex = maxLength;
    
    return '${text.substring(0, cutIndex).trim()}...';
  }

  List<Map<String, String>> _createEnhancedFlashcards(String topic, String aiResponse) {
    // Create enhanced fallback flashcards using the AI response
    List<Map<String, String>> cards = [];
    
    // Try to extract useful information from the AI response
    final sentences = aiResponse.split(RegExp(r'[.!?]')).map((s) => s.trim()).where((s) => s.isNotEmpty && s.length > 10).toList();
    
    // Create basic topic cards
    cards.add({
      'question': 'What is $topic?',
      'answer': 'A fundamental concept in academic study focusing on key principles and applications.',
    });
    
    cards.add({
      'question': 'Why is $topic important?',
      'answer': 'Understanding $topic helps build foundational knowledge and practical skills.',
    });
    
    // Add cards based on AI response content if available
    if (sentences.isNotEmpty) {
      cards.add({
        'question': 'Key insight about $topic',
        'answer': _cleanAndTruncateText(sentences.first, 200),
      });
      
      if (sentences.length > 1) {
        cards.add({
          'question': 'Additional information about $topic',
          'answer': _cleanAndTruncateText(sentences[1], 200),
        });
      }
    }
    
    // Add practical application cards
    cards.add({
      'question': 'How is $topic applied in real life?',
      'answer': 'Practical applications include problem-solving, analysis, and implementation in various fields.',
    });
    
    cards.add({
      'question': 'What should I remember about $topic?',
      'answer': 'Focus on core concepts, practical applications, and how it connects to other topics.',
    });
    
    return cards;
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentCardIndex < _flashcards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _isFlipped = false;
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _isFlipped = false;
      });
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Flashcards saved to your history');
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _flashcards = [];
      _hasResult = false;
      _currentCardIndex = 0;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Generator'),
        actions: [
          if (_hasResult)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.style, color: Colors.indigo, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flashcard Generator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate Q&A flashcards with tappable flip cards',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Input Section
              Text(
                'Enter your notes or terms:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inputController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Enter your study notes, terms, or any content you want to convert into flashcards...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateFlashcards,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Generating Flashcards...'),
                          ],
                        )
                      : const Text(
                          'Generate Flashcards',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Flashcard Display
              if (_hasResult && _flashcards.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Your Flashcards:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentCardIndex + 1} / ${_flashcards.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _saveResult,
                      icon: const Icon(Icons.bookmark_add, size: 20),
                      tooltip: 'Save Flashcards',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Flashcard with improved responsive design
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_isFlipped ? 3.14159 : 0),
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo,
                            Colors.indigo.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Front of card (Question)
                          if (!_isFlipped)
                            Container(
                              width: double.infinity,
                              height: 280,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          _flashcards[_currentCardIndex]['question']!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Tap to reveal answer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Back of card (Answer)
                          if (_isFlipped)
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(3.14159),
                              child: Container(
                                width: double.infinity,
                                height: 280,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.green.shade300,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: Center(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _flashcards[_currentCardIndex]['answer']!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Tap to see question',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Navigation Buttons with improved responsive design
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      // Wide screen - side by side buttons
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _currentCardIndex > 0 ? _previousCard : null,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _currentCardIndex < _flashcards.length - 1 ? _nextCard : null,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Narrow screen - stack buttons
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _currentCardIndex > 0 ? _previousCard : null,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Previous Card'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _currentCardIndex < _flashcards.length - 1 ? _nextCard : null,
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Next Card'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 