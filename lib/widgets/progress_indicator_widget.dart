import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProgressIndicatorWidget extends StatefulWidget {
  final String title;
  final List<String> stages;
  final bool isVisible;
  final VoidCallback? onComplete;
  
  const ProgressIndicatorWidget({
    super.key,
    required this.title,
    required this.stages,
    required this.isVisible,
    this.onComplete,
  });

  @override
  State<ProgressIndicatorWidget> createState() => _ProgressIndicatorWidgetState();
}

class _ProgressIndicatorWidgetState extends State<ProgressIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  int _currentStage = 0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ProgressIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startProgress();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _resetProgress();
    }
  }

  void _startProgress() {
    _currentStage = 0;
    _progress = 0.0;
    _animateToNextStage();
  }

  void _animateToNextStage() {
    if (_currentStage < widget.stages.length) {
      final targetProgress = (_currentStage + 1) / widget.stages.length;
      
      _animationController.reset();
      _progressAnimation = Tween<double>(
        begin: _progress,
        end: targetProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.forward().then((_) {
        setState(() {
          _progress = targetProgress;
          _currentStage++;
        });
        
        if (_currentStage < widget.stages.length && mounted && widget.isVisible) {
          // Move to next stage after a shorter delay
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && widget.isVisible) {
              _animateToNextStage();
            }
          });
        } else {
          // Completed
          Future.delayed(const Duration(milliseconds: 200), () {
            if (widget.onComplete != null) {
              widget.onComplete!();
            }
          });
        }
      });
    }
  }

  void _resetProgress() {
    _animationController.reset();
    _currentStage = 0;
    _progress = 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Progress Circle
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                // Background circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                ),
                
                // Progress circle
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(_progressAnimation.value),
                        ),
                      ),
                    );
                  },
                ),
                
                // Percentage text
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final percentage = (_progressAnimation.value * 100).round();
                        return Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Current stage
          if (_currentStage < widget.stages.length)
            Column(
              children: [
                Text(
                  'Step ${_currentStage + 1} of ${widget.stages.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.stages[_currentStage],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Stage indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.stages.length, (index) {
              final isCompleted = index < _currentStage;
              final isCurrent = index == _currentStage;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue
                          : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) return Colors.red;
    if (progress < 0.66) return Colors.orange;
    return Colors.green;
  }
}

// Progress stages for different tasks
class ProgressStages {
  static const List<String> summary = [
    'Analyzing text content...',
    'Identifying key points...',
    'Generating summary...',
    'Finalizing results...',
  ];
  
  static const List<String> quiz = [
    'Processing topic content...',
    'Analyzing difficulty level...',
    'Generating questions...',
    'Creating answer options...',
    'Finalizing quiz...',
  ];
  
  static const List<String> concept = [
    'Understanding the concept...',
    'Researching related topics...',
    'Structuring explanation...',
    'Adding examples...',
    'Finalizing content...',
  ];
  
  static const List<String> assignment = [
    'Analyzing assignment topic...',
    'Researching key points...',
    'Structuring outline...',
    'Generating content...',
    'Polishing final draft...',
  ];
  
  static const List<String> studyPlan = [
    'Evaluating study goals...',
    'Analyzing time constraints...',
    'Creating schedule framework...',
    'Optimizing study sessions...',
    'Finalizing study plan...',
  ];
  
  static const List<String> flashcards = [
    'Processing study material...',
    'Identifying key concepts...',
    'Creating question-answer pairs...',
    'Optimizing for memorization...',
    'Finalizing flashcards...',
  ];
  
  static const List<String> debate = [
    'Analyzing debate topic...',
    'Researching arguments...',
    'Building pro arguments...',
    'Building counter arguments...',
    'Structuring debate content...',
  ];
} 