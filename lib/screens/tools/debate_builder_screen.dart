import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/openrouter_service.dart';

class DebateBuilderScreen extends StatefulWidget {
  const DebateBuilderScreen({super.key});

  @override
  State<DebateBuilderScreen> createState() => _DebateBuilderScreenState();
}

class _DebateBuilderScreenState extends State<DebateBuilderScreen> {
  final TextEditingController _topicController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic> _result = {};
  bool _hasResult = false;
  String _selectedTab = 'arguments';

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _generateDebateContent() async {
    if (_topicController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a debate topic');
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
      // Call OpenRouter API for both pro and against arguments
      final proResponse = await OpenRouterService.buildDebateArguments(
        topic: _topicController.text.trim(),
        position: 'pro',
      );

      final againstResponse = await OpenRouterService.buildDebateArguments(
        topic: _topicController.text.trim(),
        position: 'against',
      );

      // Mock debate content structure with API responses
      _result = {
        'topic': _topicController.text,
        'argumentsFor': [
          proResponse.split('\n').where((line) => line.trim().isNotEmpty).take(5).toList(),
        ].expand((x) => x).toList(),
        'argumentsAgainst': [
          againstResponse.split('\n').where((line) => line.trim().isNotEmpty).take(5).toList(),
        ].expand((x) => x).toList(),
        'speech': proResponse, // Use the pro response as the main speech
      };

      setState(() {
        _isLoading = false;
        _hasResult = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to generate debate content: ${e.toString()}');
    }
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Debate content saved to your history');
  }

  void _copyContent() {
    // TODO: Copy to clipboard
    Get.snackbar('Copied', 'Content copied to clipboard');
  }

  void _clearAll() {
    setState(() {
      _topicController.clear();
      _result = {};
      _hasResult = false;
      _selectedTab = 'arguments';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debate Builder'),
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debate Builder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create arguments and speeches for debates',
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
                'Enter debate topic:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topicController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter a debate topic (e.g., "Should social media be regulated?", "Is remote work better than office work?")',
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
                  onPressed: _isLoading ? null : _generateDebateContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                            Text('Generating Debate Content...'),
                          ],
                        )
                      : const Text(
                          'Generate Debate Content',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Results Section
              if (_hasResult) ...[
                Row(
                  children: [
                    Text(
                      'Debate Content:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _copyContent,
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
                const SizedBox(height: 16),
                // Tab Navigation
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 'arguments'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 'arguments' ? Colors.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Arguments',
                              style: TextStyle(
                                color: _selectedTab == 'arguments' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 'speech'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 'speech' ? Colors.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sample Speech',
                              style: TextStyle(
                                color: _selectedTab == 'speech' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Content Display
                if (_selectedTab == 'arguments') ...[
                  // Arguments For
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_outlined, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Arguments For',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_result['argumentsFor'] as List<String>).map((argument) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    argument,
                                    style: const TextStyle(fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  // Arguments Against
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thumb_down_outlined, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Arguments Against',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_result['argumentsAgainst'] as List<String>).map((argument) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6, right: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    argument,
                                    style: const TextStyle(fontSize: 14, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ] else if (_selectedTab == 'speech') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Sample Speech (1-minute)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _result['speech'],
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyContent,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Content'),
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
                          backgroundColor: Colors.red,
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