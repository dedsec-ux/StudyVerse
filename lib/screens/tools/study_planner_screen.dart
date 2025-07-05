import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/openrouter_service.dart';
import '../../widgets/progress_indicator_widget.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  bool _isLoading = false;
  String _result = '';
  bool _hasResult = false;
  List<Map<String, dynamic>> _studyPlan = [];

  @override
  void dispose() {
    _subjectController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _generateStudyPlan() async {
    if (_subjectController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a subject');
      return;
    }

    if (_daysController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter number of days');
      return;
    }

    final days = int.tryParse(_daysController.text);
    if (days == null || days <= 0) {
      Get.snackbar('Error', 'Please enter a valid number of days');
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
      final response = await OpenRouterService.createStudyPlan(
        subject: _subjectController.text.trim(),
        studyHours: int.tryParse(_hoursController.text) ?? 2,
        timeframe: '$days days',
      );

      // For now, store the response as a single result
      // You can later parse this into individual study plan items
      setState(() {
        _isLoading = false;
        _result = response;
        _hasResult = true;
        // Generate visual study plan for UI
        _studyPlan = _generateMockStudyPlan(
          _subjectController.text,
          days,
          int.tryParse(_hoursController.text) ?? 2,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to generate study plan: ${e.toString()}');
    }
  }

  List<Map<String, dynamic>> _generateMockStudyPlan(String subject, int days, int hoursPerDay) {
    List<Map<String, dynamic>> plan = [];
    
    // Sample study topics for different phases
    List<String> topics = [
      'Introduction and Overview',
      'Basic Concepts and Definitions',
      'Core Principles and Theories',
      'Practical Applications',
      'Advanced Topics',
      'Case Studies and Examples',
      'Problem Solving Practice',
      'Review and Consolidation',
      'Mock Tests and Assessments',
      'Final Revision',
    ];

    for (int i = 0; i < days; i++) {
      String phase;
      String focus;
      List<String> tasks = [];
      
      double progress = (i + 1) / days;
      
      if (progress <= 0.3) {
        phase = 'Foundation Phase';
        focus = 'Building basic understanding';
        tasks = [
          'Read introduction materials',
          'Take notes on key concepts',
          'Create vocabulary list',
          'Watch introductory videos',
        ];
      } else if (progress <= 0.6) {
        phase = 'Development Phase';
        focus = 'Deepening knowledge';
        tasks = [
          'Study core principles',
          'Practice problems',
          'Create concept maps',
          'Join study groups',
        ];
      } else if (progress <= 0.8) {
        phase = 'Application Phase';
        focus = 'Applying knowledge';
        tasks = [
          'Work on practice exercises',
          'Analyze case studies',
          'Create project work',
          'Teach concepts to others',
        ];
      } else {
        phase = 'Mastery Phase';
        focus = 'Review and perfect';
        tasks = [
          'Complete practice tests',
          'Review weak areas',
          'Final consolidation',
          'Prepare for assessment',
        ];
      }

      plan.add({
        'day': i + 1,
        'date': DateTime.now().add(Duration(days: i)),
        'phase': phase,
        'focus': focus,
        'topic': topics[i % topics.length],
        'duration': '$hoursPerDay hours',
        'tasks': tasks,
        'completed': false,
      });
    }

    return plan;
  }

  void _saveResult() {
    // TODO: Save to Firestore
    Get.snackbar('Saved', 'Study plan saved to your history');
  }

  void _markDayComplete(int index) {
    setState(() {
      _studyPlan[index]['completed'] = !_studyPlan[index]['completed'];
    });
  }

  void _clearAll() {
    setState(() {
      _subjectController.clear();
      _daysController.clear();
      _hoursController.clear();
      _result = '';
      _hasResult = false;
      _studyPlan = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
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
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Study Planner',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create personalized daily study schedules',
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
              // Subject Input
              Text(
                'Subject/Topic:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Enter subject (e.g., "Mathematics", "History", "Programming")',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              // Study Duration Inputs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Days until exam:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g., 14',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hours per day:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g., 2',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateStudyPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
                            Text('Creating Study Plan...'),
                          ],
                        )
                      : const Text(
                          'Create Study Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Study Plan Display
              if (_hasResult) ...[
                Row(
                  children: [
                    Text(
                      'Your Study Plan:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saveResult,
                      icon: const Icon(Icons.bookmark_add, size: 20),
                      tooltip: 'Save Plan',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Study Plan Timeline
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _studyPlan.length,
                  itemBuilder: (context, index) {
                    final day = _studyPlan[index];
                    final isCompleted = day['completed'] as bool;
                    final date = day['date'] as DateTime;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompleted ? Colors.green : Colors.grey[200]!,
                          width: isCompleted ? 2 : 1,
                        ),
                      ),
                      child: ExpansionTile(
                        leading: GestureDetector(
                          onTap: () => _markDayComplete(index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted ? Icons.check : Icons.schedule,
                              color: isCompleted ? Colors.white : Colors.grey[600],
                              size: 16,
                            ),
                          ),
                        ),
                        title: Text(
                          'Day ${day['day']} - ${day['topic']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.day}/${date.month}/${date.year} • ${day['duration']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day['phase'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Focus: ${day['focus']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Today\'s Tasks:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(day['tasks'] as List<String>).map((task) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(top: 6, right: 8),
                                          decoration: const BoxDecoration(
                                            color: Colors.teal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            task,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Progress Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress Tracking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete ${_studyPlan.where((day) => day['completed']).length} / ${_studyPlan.length} days',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
} 