import 'package:flutter/material.dart';
import 'task_group.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/services/task_assign/task_group_service.dart';
import 'package:flutter_app/components/tasks/info_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskGroup taskGroup;

  const TaskDetailPage({Key? key, required this.taskGroup}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage>
    with TickerProviderStateMixin {
  String selectedFilter = "All";
  bool isLoading = false;
  final TaskGroupService _taskGroupService = TaskGroupService();
  List<Task> allTasks = [];
  // Remove late keyword to avoid initialization error
  AnimationController? _progressAnimationController;
  bool _isAnimationReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with try-catch for safety
    try {
      _progressAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _isAnimationReady = true;
    } catch (e) {
      print('Error initializing animation controller: $e');
      _isAnimationReady = false;
    }

    // Start with the tasks we already have
    allTasks = widget.taskGroup.tasks;

    // Refresh tasks immediately when page loads
    _refreshTasks();

    // Start progress animation if controller was initialized successfully
    if (_isAnimationReady && _progressAnimationController != null) {
      _progressAnimationController!.forward();
    }
  }

  @override
  void dispose() {
    // Safely dispose animation controller
    if (_progressAnimationController != null) {
      _progressAnimationController!.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      print(
          'Fetching tasks for group: ${widget.taskGroup.reportId ?? "unknown"}');

      if (widget.taskGroup.reportId == null ||
          widget.taskGroup.reportId!.isEmpty) {
        print(
            'Warning: Empty reportId for task group ${widget.taskGroup.title}');
      }

      final tasks = await _taskGroupService
          .getTasksForGroup(widget.taskGroup.reportId ?? '');

      print('Received ${tasks.length} tasks from API');

      if (mounted) {
        setState(() {
          allTasks = tasks;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error refreshing tasks: $e');

      // Show snackbar with error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tasks: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<Task> getFilteredTasks() {
    if (selectedFilter == "To do") {
      return allTasks.where((task) => !task.isCompleted).toList();
    } else if (selectedFilter == "Completed") {
      return allTasks.where((task) => task.isCompleted).toList();
    }
    return allTasks;
  }

  void toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;

      // Log the update operation
      print(
          'Updating task "${task.title}" status to ${task.isCompleted ? "completed" : "not completed"}');
      print('Using reportId: ${widget.taskGroup.reportId}');

      // Update in backend
      _taskGroupService
          .updateTaskStatus(
        widget.taskGroup.reportId ?? '',
        task.title, // Using title as ID
        task.isCompleted,
      )
          .then((success) {
        if (!success && mounted) {
          // If update failed, revert the UI change
          setState(() {
            task.isCompleted = !task.isCompleted;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update task status'),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      });
    });
  }

  // Add a method to navigate to task details
  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => InfoCard(
          taskTitle: task.title,
          taskDescription:
              "This task is to enhance your eye contact skills, which are crucial for effective communication and building rapport.",
          // Add other details you want to pass
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = getFilteredTasks();

    // Create animation only if controller is ready
    final progressAnimation =
        _isAnimationReady && _progressAnimationController != null
            ? Tween<double>(begin: 0.0, end: widget.taskGroup.progress)
                .animate(CurvedAnimation(
                parent: _progressAnimationController!,
                curve: Curves.easeOut,
              ))
            : null;

    // Get theme color based on task group title
    final themeColor = _getTaskGroupTheme(widget.taskGroup.title);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF7400B8), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor['color']!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(themeColor['icon'] as IconData,
                  color: themeColor['color'], size: 22),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.taskGroup.title,
                style: const TextStyle(
                  color: Color(0xFF2D3142),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF7400B8)),
            onPressed: _refreshTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        backgroundColor: Colors.white,
        color: themeColor['color'] as Color,
        strokeWidth: 3,
        displacement: 20,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Task Header Card - Enhanced
                _buildProgressHeader(
                    progressAnimation, themeColor, filteredTasks),

                const SizedBox(height: 24),

                // Enhanced Filter Selection
                _buildFilterSelectionBar(),

                const SizedBox(height: 20),

                // Task List with Animations
                Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: isLoading
                      ? _buildEnhancedLoadingState()
                      : filteredTasks.isEmpty
                          ? _buildEnhancedEmptyState(themeColor)
                          : _buildTaskListView(filteredTasks, themeColor),
                ),

                // Add some padding at the bottom for better scrolling
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feature coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: themeColor['color'] as Color,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 2),
    );
  }

  Widget _buildProgressHeader(Animation<double>? progressAnimation,
      Map<String, dynamic> themeColor, List<Task> tasks) {
    int completedTasks = tasks.where((task) => task.isCompleted).length;
    int totalTasks = tasks.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor['color'] as Color,
            (themeColor['color'] as Color).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (themeColor['color'] as Color).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Task Progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completedTasks == totalTasks && totalTasks > 0
                        ? "All tasks completed!"
                        : "Keep going, you're doing great!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  themeColor['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Use animation safely, with fallback for when animation isn't ready
          _isAnimationReady && progressAnimation != null
              ? AnimatedBuilder(
                  animation: _progressAnimationController!,
                  builder: (context, child) {
                    return _buildEnhancedProgressContent(
                      progressAnimation.value,
                      completedTasks,
                      totalTasks,
                    );
                  },
                )
              : _buildEnhancedProgressContent(
                  widget.taskGroup.progress,
                  completedTasks,
                  totalTasks,
                ),
        ],
      ),
    );
  }

  // Enhanced progress bar and stats UI
  Widget _buildEnhancedProgressContent(
      double progressValue, int completedTasks, int totalTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced progress bar with animation
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background
              Container(
                height: 12,
                color: Colors.white.withOpacity(0.2),
              ),
              // Progress
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 12,
                width: MediaQuery.of(context).size.width * 0.8 * progressValue,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Percentage completed
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${(progressValue * 100).toInt()}% Done",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // Task count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$completedTasks of $totalTasks Tasks",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterTab("All", Icons.view_list_rounded, allTasks.length),
          _buildFilterTab("To do", Icons.pending_actions_rounded,
              allTasks.where((task) => !task.isCompleted).length),
          _buildFilterTab("Completed", Icons.task_alt_rounded,
              allTasks.where((task) => task.isCompleted).length),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, IconData icon, int count) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7400B8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListView(List<Task> tasks, Map<String, dynamic> themeColor) {
    return AnimationLimiter(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEnhancedTaskCard(tasks[index], themeColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTaskCard(Task task, Map<String, dynamic> themeColor) {
    Color statusColor =
        task.isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToTaskDetails(task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox with enhanced design
                  GestureDetector(
                    onTap: () => toggleTaskCompletion(task),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? themeColor['color'] as Color
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: task.isCompleted
                              ? themeColor['color'] as Color
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: task.isCompleted
                            ? [
                                BoxShadow(
                                  color: (themeColor['color'] as Color)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: task.isCompleted
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Task details column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title with strike-through when completed
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isCompleted
                                ? Colors.grey.shade400
                                : Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Task status
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.isCompleted ? "Completed" : "In progress",
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Info button
                  Container(
                    height: 30,
                    width: 30,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _navigateToTaskDetails(task),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLoadingState() {
    return Column(
      children: List.generate(5, (index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEnhancedEmptyState(Map<String, dynamic> themeColor) {
    // Different illustrations and messages based on filter
    String message = selectedFilter == "All"
        ? "No tasks available in this collection"
        : selectedFilter == "To do"
            ? "No pending tasks - great job!"
            : "No completed tasks yet";

    String submessage = selectedFilter == "All"
        ? "Tasks will appear here when they're created"
        : selectedFilter == "To do"
            ? "All your tasks are completed!"
            : "Mark tasks as done to see them here";

    IconData iconData = selectedFilter == "All"
        ? Icons.list_alt_rounded
        : selectedFilter == "To do"
            ? Icons.check_circle_outline_rounded
            : Icons.task_alt_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (themeColor['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: themeColor['color'] as Color,
              size: 45,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Get theme colors and icons based on task group name
  Map<String, dynamic> _getTaskGroupTheme(String title) {
    final normalizedTitle = title.toLowerCase();

    if (normalizedTitle.contains('presentation')) {
      return {
        'color': const Color(0xFFE91E63), // Pink
        'icon': Icons.slideshow_rounded,
      };
    } else if (normalizedTitle.contains('meeting')) {
      return {
        'color': const Color(0xFF2196F3), // Blue
        'icon': Icons.groups_rounded,
      };
    } else if (normalizedTitle.contains('project')) {
      return {
        'color': const Color(0xFFFF9800), // Orange
        'icon': Icons.engineering_rounded,
      };
    } else if (normalizedTitle.contains('report')) {
      return {
        'color': const Color(0xFF4CAF50), // Green
        'icon': Icons.description_rounded,
      };
    } else if (normalizedTitle.contains('interview')) {
      return {
        'color': const Color(0xFF9C27B0), // Purple
        'icon': Icons.record_voice_over_rounded,
      };
    } else {
      return {
        'color': const Color(0xFF7400B8), // Default Purple
        'icon': Icons.task_alt_rounded,
      };
    }
  }
}
