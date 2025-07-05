import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/progress_indicator_widget.dart';

class AssignmentHelperScreen extends StatefulWidget {
  const AssignmentHelperScreen({super.key});

  @override
  State<AssignmentHelperScreen> createState() => _AssignmentHelperScreenState();
}

class _AssignmentHelperScreenState extends State<AssignmentHelperScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLoading = false;
  String _tone = 'Formal';
  String _result = '';
  bool _hasResult = false;
  bool _showProgress = false;

  final List<String> _tones = ['Formal', 'Technical', 'Friendly'];

  @override
  void dispose() {
    _topicController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _generateAssignment() async {
    if (_topicController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a topic for your assignment');
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
      _showProgress = true;
    });

    try {
      // Call OpenRouter API
      final response = await OpenRouterService.helpWithAssignment(
        topic: _topicController.text.trim(),
        assignmentType: 'essay', // You can make this configurable
        tone: _tone,
        additionalRequirements: _instructionsController.text.trim().isNotEmpty 
            ? _instructionsController.text.trim() 
            : null,
      );

      setState(() {
        _isLoading = false;
        _result = response;
        _hasResult = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to generate assignment: ${e.toString()}');
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Assignment saved to your history');
  }

  void _copyResult() {
    // TODO: Copy to clipboard
    Get.snackbar('Copied', 'Assignment copied to clipboard');
  }

  void _clearAll() {
    setState(() {
      _topicController.clear();
      _instructionsController.clear();
      _result = '';
      _hasResult = false;
      _tone = 'Formal';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Helper'),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assignment Helper',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get help with essays, articles, and assignments',
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
              // Topic Input
              Text(
                'Assignment Topic:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'Enter your assignment topic (e.g., "Climate Change", "Ancient Rome", "Machine Learning")',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              // Instructions Input
              Text(
                'Additional Instructions (Optional):',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Any specific requirements, length, focus areas, or guidelines...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              // Tone Selection
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
                      'Writing Tone:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _tones.map((tone) {
                        final isSelected = _tone == tone;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tone),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _tone = tone;
                                });
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: Colors.purple.withOpacity(0.2),
                              checkmarkColor: Colors.purple,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.purple : Colors.grey[600],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
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
                  onPressed: _isLoading ? null : _generateAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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
                            Text('Generating Assignment...'),
                          ],
                        )
                      : const Text(
                          'Generate Assignment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Result Section
              if (_hasResult) ...[
                Row(
                  children: [
                    Text(
                      'Generated Assignment:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _copyResult,
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      onPressed: _saveResult,
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
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyResult,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveResult,
                        icon: const Icon(Icons.bookmark_add, size: 18),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 