import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/progress_indicator_widget.dart';

class QuizMakerScreen extends StatefulWidget {
  const QuizMakerScreen({super.key});

  @override
  State<QuizMakerScreen> createState() => _QuizMakerScreenState();
}

class _QuizMakerScreenState extends State<QuizMakerScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String _questionType = 'Mixed';
  String _result = '';
  bool _hasResult = false;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _showProgress = false;

  final List<String> _questionTypes = [
    'Mixed',
    'Multiple Choice',
    'True/False',
    'Fill in the Blanks',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateQuiz() async {
    if (_inputController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a topic or content for the quiz');
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
      // Call OpenRouter API
      final response = await OpenRouterService.generateQuiz(
        topic: _inputController.text.trim(),
        questionCount: 5,
        questionType: _questionType,
      );

      print('Quiz API Response: $response'); // Debug print
      print('Response length: ${response.length}'); // Debug print

      // Parse the response to extract individual questions
      // For now, we'll store the full response as a single result
      // You can later add parsing logic to extract individual questions
      setState(() {
        _isLoading = false;
        _result = response;
        _hasResult = response.isNotEmpty; // Ensure this is properly set
        _currentQuestionIndex = 0;
        // Reset questions for now - you can parse the response later
        _questions = [];
      });
      
      print('_hasResult: $_hasResult'); // Debug print
      print('_result length: ${_result.length}'); // Debug print
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to generate quiz: ${e.toString()}');
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Quiz saved to your history');
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _result = '';
      _hasResult = false;
      _questions = [];
      _currentQuestionIndex = 0;
      _questionType = 'Mixed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Maker'),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quiz Maker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate quiz questions automatically from your content',
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
                'Enter topic or content for quiz:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inputController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Enter a topic (e.g., "World War II") or paste your study content...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              // Question Type Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Type:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _questionTypes.map((type) {
                        final isSelected = _questionType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _questionType = type;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Colors.green.withOpacity(0.2),
                          checkmarkColor: Colors.green,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                            Text('Generating Quiz...'),
                          ],
                        )
                      : const Text(
                          'Generate Quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Result Display
              if (_hasResult) ...[
                Row(
                  children: [
                    Text(
                      'Generated Quiz:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // Copy result
                        Get.snackbar('Copied', 'Quiz copied to clipboard');
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      onPressed: () {
                        // Save result
                        Get.snackbar('Saved', 'Quiz saved to your history');
                      },
                      icon: const Icon(Icons.bookmark_add, size: 20),
                      tooltip: 'Save',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SelectableText(
                    _result,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 