import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/progress_indicator_widget.dart';

class SmartSummaryScreen extends StatefulWidget {
  const SmartSummaryScreen({super.key});

  @override
  State<SmartSummaryScreen> createState() => _SmartSummaryScreenState();
}

class _SmartSummaryScreenState extends State<SmartSummaryScreen> with WidgetsBindingObserver, FullScreenMixin {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  bool _explainLikeChild = false;
  String _result = '';
  bool _hasResult = false;
  bool _showProgress = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateSummary() async {
    if (_inputController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter some text to summarize');
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
      final response = await OpenRouterService.generateSummary(
        text: _inputController.text.trim(),
        explainLikeChild: _explainLikeChild,
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
      Get.snackbar('Error', 'Failed to generate summary: ${e.toString()}');
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Summary saved to your history');
  }

  void _copyResult() {
    // TODO: Copy to clipboard
    Get.snackbar('Copied', 'Summary copied to clipboard');
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _result = '';
      _hasResult = false;
      _explainLikeChild = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Summary'),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.summarize, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Smart Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get clean, bullet-point summaries of your notes',
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
                    const SizedBox(height: 20),
                    // Input Section
                    Text(
                      'Enter your text to summarize:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.25,
                        minHeight: 120,
                      ),
                      child: TextField(
                        controller: _inputController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'Paste your notes, textbook content, or any text you want to summarize...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Toggle Options
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
                            'Summary Options:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: _explainLikeChild,
                                onChanged: (value) {
                                  setState(() {
                                    _explainLikeChild = value;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Explain like I\'m 10 years old',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateSummary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
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
                                  Text('Generating Summary...'),
                                ],
                              )
                            : const Text(
                                'Generate Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Result Section
                    if (_hasResult) ...[
                      Row(
                        children: [
                          Text(
                            'AI Summary:',
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
                      const SizedBox(height: 16),
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
                                backgroundColor: Colors.blue,
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
                    SizedBox(height: screenHeight * 0.05),
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