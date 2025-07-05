import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/progress_indicator_widget.dart';

class ConceptExplainerScreen extends StatefulWidget {
  const ConceptExplainerScreen({super.key});

  @override
  State<ConceptExplainerScreen> createState() => _ConceptExplainerScreenState();
}

class _ConceptExplainerScreenState extends State<ConceptExplainerScreen> with WidgetsBindingObserver, FullScreenMixin {
  final TextEditingController _conceptController = TextEditingController();
  final TextEditingController _concept2Controller = TextEditingController();
  bool _isLoading = false;
  String _difficultyLevel = 'Simple';
  bool _compareMode = false;
  Map<String, String> _results = {};
  bool _hasResult = false;
  bool _showProgress = false;

  final List<String> _difficultyLevels = ['Simple', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _conceptController.dispose();
    _concept2Controller.dispose();
    super.dispose();
  }

  void _explainConcept() async {
    if (_conceptController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a concept to explain');
      return;
    }

    if (_compareMode && _concept2Controller.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter the second concept for comparison');
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
      final response = await OpenRouterService.explainConcept(
        concept: _conceptController.text.trim(),
        difficultyLevel: _difficultyLevel,
        secondConcept: _compareMode ? _concept2Controller.text.trim() : null,
      );

      setState(() {
        _isLoading = false;
        _results = _compareMode 
          ? {'comparison': response}
          : {'explanation': response};
        _hasResult = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to explain concept: ${e.toString()}');
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Explanation saved to your history');
  }

  void _copyResult() {
    // TODO: Copy to clipboard
    Get.snackbar('Copied', 'Explanation copied to clipboard');
  }

  void _clearAll() {
    setState(() {
      _conceptController.clear();
      _concept2Controller.clear();
      _results = {};
      _hasResult = false;
      _difficultyLevel = 'Simple';
      _compareMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concept Explainer'),
        actions: [
          if (_hasResult)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tool Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Concept Explainer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Understand topics at different complexity levels',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Mode Toggle - Fixed overflow
                    Text(
                      'Mode:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Single Concept'),
                          selected: !_compareMode,
                          onSelected: (selected) {
                            setState(() {
                              _compareMode = !selected;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Colors.orange.withOpacity(0.2),
                        ),
                        FilterChip(
                          label: const Text('Compare Concepts'),
                          selected: _compareMode,
                          onSelected: (selected) {
                            setState(() {
                              _compareMode = selected;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Input Section
                    Text(
                      _compareMode ? 'Enter concepts to compare:' : 'Enter concept to explain:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.15,
                        minHeight: 80,
                      ),
                      child: TextField(
                        controller: _conceptController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'Enter a concept (e.g., "Quantum Physics", "Democracy")',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    if (_compareMode) ...[
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.15,
                          minHeight: 80,
                        ),
                        child: TextField(
                          controller: _concept2Controller,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Enter second concept to compare',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Difficulty Level (only for single concept mode) - Fixed overflow
                    if (!_compareMode) ...[
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
                              'Explanation Level:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _difficultyLevels.map((level) {
                                final isSelected = _difficultyLevel == level;
                                return FilterChip(
                                  label: Text(
                                    level,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.orange : Colors.grey[600],
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _difficultyLevel = level;
                                    });
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: Colors.orange.withOpacity(0.2),
                                  checkmarkColor: Colors.orange,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _explainConcept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                                  Text('Generating Explanation...'),
                                ],
                              )
                            : Text(
                                _compareMode ? 'Compare Concepts' : 'Explain Concept',
                                style: const TextStyle(
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
                            'AI Explanation:',
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
                      ..._results.entries.map((entry) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: SelectableText(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        );
                      }).toList(),
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
                                backgroundColor: Colors.orange,
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
            );
          },
        ),
      ),
    );
  }
} 