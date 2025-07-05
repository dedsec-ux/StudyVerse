import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  final List<String> _filters = [
    'All',
    'Summary',
    'Quiz',
    'Flashcards',
    'Planner',
    'Explainer',
    'Assignment',
    'Debate',
  ];

  // Mock history data
  final List<Map<String, dynamic>> _historyItems = [
    {
      'id': '1',
      'toolName': 'Smart Summary',
      'inputText': 'Photosynthesis is the process by which plants make their own food using sunlight, water, and carbon dioxide.',
      'aiOutput': '• Photosynthesis is the process plants use to make food\n• Requires sunlight, water, and carbon dioxide\n• Produces glucose and oxygen\n• Occurs in chloroplasts',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'icon': Icons.summarize_outlined,
      'color': Colors.blue,
    },
    {
      'id': '2',
      'toolName': 'Quiz Maker',
      'inputText': 'World War II history and major events',
      'aiOutput': '1. When did World War II start?\nA) 1939 B) 1940 C) 1941 D) 1942\n\n2. Which country invaded Poland?...',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'icon': Icons.quiz_outlined,
      'color': Colors.green,
    },
    {
      'id': '3',
      'toolName': 'Flashcards',
      'inputText': 'Mathematical formulas for calculus',
      'aiOutput': 'Q: What is the derivative of x²?\nA: 2x\n\nQ: What is the integral of 2x?\nA: x² + C...',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.style_outlined,
      'color': Colors.indigo,
    },
    {
      'id': '4',
      'toolName': 'Study Planner',
      'inputText': 'Chemistry exam in 7 days',
      'aiOutput': 'Day 1: Review atomic structure\nDay 2: Chemical bonding\nDay 3: Periodic table...',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'icon': Icons.schedule_outlined,
      'color': Colors.teal,
    },
    {
      'id': '5',
      'toolName': 'Concept Explainer',
      'inputText': 'Quantum physics basics',
      'aiOutput': 'Simple: Quantum physics is about very tiny particles that behave differently...',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'icon': Icons.lightbulb_outline,
      'color': Colors.orange,
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    List<Map<String, dynamic>> filtered = _historyItems;
    
    if (_selectedFilter != 'All') {
      filtered = filtered.where((item) {
        return item['toolName'].toLowerCase().contains(_selectedFilter.toLowerCase());
      }).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['inputText'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item['toolName'].toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          _showClearHistoryDialog(context);
                        },
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI interaction history',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // History List
            Expanded(
              child: _filteredHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final item = _filteredHistory[index];
                        return _buildHistoryCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'],
            color: item['color'],
            size: 20,
          ),
        ),
        title: Text(
          item['toolName'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['inputText'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(item['timestamp']),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 8),
                  Text('Copy Result'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'copy') {
              // TODO: Copy to clipboard
              Get.snackbar('Copied', 'AI result copied to clipboard');
            } else if (value == 'delete') {
              // TODO: Delete item
              Get.snackbar('Deleted', 'History item deleted');
            }
          },
        ),
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Result:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['aiOutput'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start using AI tools to see your history here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to clear all history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Clear history
                Get.snackbar('Cleared', 'History cleared successfully');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
} 