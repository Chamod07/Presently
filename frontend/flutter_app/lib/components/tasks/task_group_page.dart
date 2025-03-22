import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'task_list_page.dart';
import 'task_group.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/services/task_assign/task_group_service.dart';
import 'package:flutter_app/utils/image_utils.dart';

class TaskGroupPage extends StatefulWidget {
  const TaskGroupPage({Key? key}) : super(key: key);

  @override
  _TaskGroupPageState createState() => _TaskGroupPageState();
}

class _TaskGroupPageState extends State<TaskGroupPage>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  List<TaskGroup> taskGroups = [];
  bool isLoading = true;
  String? errorMessage;
  // Add cache variables
  static List<TaskGroup> _cachedTaskGroups = [];
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  final TaskGroupService _taskGroupService =
      TaskGroupService(); // Define service as class variable

  AnimationController? _animationController;
  bool _isAnimationReady = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with try-catch for safety
    try {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _isAnimationReady = true;
      _animationController!.forward();
    } catch (e) {
      print('Error initializing animation controller: $e');
      _isAnimationReady = false;
    }

    // Load task groups on startup
    _loadTaskGroups();
  }

  @override
  void dispose() {
    // Safely dispose animation controller
    if (_animationController != null) {
      _animationController!.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTaskGroups() async {
    // First check if we have valid cached data for immediate display
    if (_cachedTaskGroups.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
      print('Using cached data: ${_cachedTaskGroups.length} task groups');
      // Use cached data for immediate UI display
      setState(() {
        taskGroups = _cachedTaskGroups;
        isLoading = false;
      });
    } else {
      // No valid cache, so show loading state
      setState(() {
        isLoading = true;
      });
    }

    // Always fetch fresh data in the background, regardless of cache status
    _fetchTaskGroups();
  }

  Future<void> _refreshTaskGroupsInBackground() async {
    try {
      print('Starting background refresh of task groups');
      final fetchedTaskGroups = await _taskGroupService.getTaskGroups();
      print(
          'Background refresh complete: ${fetchedTaskGroups.length} task groups');

      if (mounted) {
        setState(() {
          taskGroups = fetchedTaskGroups;
          // Update cache
          _cachedTaskGroups = fetchedTaskGroups;
          _lastFetchTime = DateTime.now();
        });
      }
    } catch (e) {
      print('Background refresh error: $e');
      // Don't update UI state or show error since this is a background operation
    }
  }

  Future<void> _fetchTaskGroups() async {
    try {
      if (!isLoading) {
        // If we're showing cached data, don't show loading indicator
        setState(() {
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      print('TaskGroupPage: Fetching task groups...');

      try {
        // Check authentication status
        final token = _taskGroupService.getAuthToken();
        print(
            'TaskGroupPage: Authentication token ${token != null ? "exists" : "does not exist"}');

        // Fetch task groups
        final fetchedTaskGroups = await _taskGroupService.getTaskGroups();
        print('TaskGroupPage received ${fetchedTaskGroups.length} task groups');

        // Log details of each task group for debugging
        for (int i = 0; i < fetchedTaskGroups.length; i++) {
          final group = fetchedTaskGroups[i];
          print(
              'Task Group $i: title=${group.title}, reportId=${group.reportId}, tasks=${group.tasks.length}');
        }

        if (mounted) {
          setState(() {
            taskGroups = fetchedTaskGroups;
            isLoading = false;

            // Update cache only if we have valid data
            if (fetchedTaskGroups.isNotEmpty) {
              _cachedTaskGroups = fetchedTaskGroups;
              _lastFetchTime = DateTime.now();
            } else {
              print('Received empty task groups list, not updating cache');
            }
          });
        }
      } catch (e) {
        // This provides better error messaging to the user
        if (mounted) {
          setState(() {
            // If we have cached data, show it instead of clearing everything
            if (_cachedTaskGroups.isNotEmpty) {
              taskGroups = _cachedTaskGroups;
              errorMessage =
                  'Using cached data. Unable to refresh from server.';
            } else {
              taskGroups = []; // Clear any existing data
              errorMessage =
                  'Unable to connect to the server. Please try again later.';
            }
            isLoading = false;
          });

          // Show a snackbar with error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _fetchTaskGroups,
              ),
            ),
          );
        }
        print('Error in fetch: $e');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An unexpected error occurred.';
          isLoading = false;
        });
      }
      print('Unexpected error: $e');
    }
  }

  // Clear the cache if needed
  void _clearCache() {
    setState(() {
      _cachedTaskGroups = [];
      _lastFetchTime = null;
    });
    _fetchTaskGroups();
  }

  // Modify refresh function to also clear cache
  Future<void> _refreshTaskGroups() async {
    // Clear cache first for a fresh start
    _cachedTaskGroups = [];
    _lastFetchTime = null;

    // Then fetch fresh data
    await _fetchTaskGroups();
  }

  // Navigate to task detail page with the selected task group
  void _navigateToTaskDetail(TaskGroup taskGroup) {
    print(
        'Navigating to tasks for group: ${taskGroup.title} (${taskGroup.reportId})');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(taskGroup: taskGroup),
        // Pass the selectedIndex to maintain consistency
        settings: const RouteSettings(
          arguments: {'selectedIndex': 2},
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  double _calculateOverallProgress() {
    if (taskGroups.isEmpty) return 0.0;
    return taskGroups.fold<double>(0.0, (sum, group) => sum + group.progress) /
        taskGroups.length;
  }

  Widget _buildSimpleTaskGroupCard(TaskGroup taskGroup) {
    // Different colors for different progress levels
    final progressColor = taskGroup.progress < 0.3
        ? Colors.redAccent
        : taskGroup.progress < 0.7
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetail(taskGroup),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Task Group Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF7400B8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.task_alt,
                    color: Color(0xFF7400B8),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Task Group Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskGroup.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${taskGroup.taskCount} tasks",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    // Linear Progress Indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: taskGroup.progress,
                        backgroundColor: Colors.grey.shade200,
                        color: progressColor,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: taskGroup.progress,
                      color: progressColor,
                      backgroundColor: Colors.grey.shade200,
                      strokeWidth: 5.0,
                    ),
                  ),
                  Text(
                    "${(taskGroup.progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(double progress) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7400B8), Color(0xFF6930C3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7400B8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your overall progress!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Keep going, you're doing great!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                          value: progress * 100,
                          color: Colors.white,
                          radius: 10,
                          title: ""),
                      PieChartSectionData(
                          value: 100 - (progress * 100),
                          color: Colors.white.withOpacity(0.3),
                          radius: 10,
                          title: ""),
                    ],
                    centerSpaceRadius: 25,
                    sectionsSpace: 0,
                  ),
                ),
                Text("${(progress * 100).toInt()}%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double overallProgress = _calculateOverallProgress();
    final progressAnimation = _isAnimationReady && _animationController != null
        ? Tween<double>(begin: 0.0, end: overallProgress)
            .animate(CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeOutQuart,
          ))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      // Enhanced App Bar
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF7400B8), size: 22),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7400B8), Color(0xFF6930C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7400B8).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              "My Tasks",
              style: TextStyle(
                color: Color(0xFF2D3142),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button with animation effects
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF7400B8)),
            onPressed: () {
              // Add a visual feedback for refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing task collections...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF7400B8),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              );
              _refreshTaskGroups();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTaskGroups,
        color: const Color(0xFF7400B8),
        backgroundColor: Colors.white,
        strokeWidth: 3,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced animated progress card
                _isAnimationReady &&
                        _animationController != null &&
                        progressAnimation != null
                    ? AnimatedBuilder(
                        animation: _animationController!,
                        builder: (context, _) =>
                            _buildEnhancedProgressCard(progressAnimation.value),
                      )
                    : _buildEnhancedProgressCard(overallProgress),
                const SizedBox(height: 30),

                // Enhanced section header
                _buildSectionHeader("Your Collections",
                    Icons.folder_special_rounded, taskGroups.length.toString()),

                const SizedBox(height: 20),

                // Enhanced task groups list with better animations
                _buildEnhancedTaskGroups(),

                // Add padding at bottom for better scrolling
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      // Enhanced floating action button
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7400B8), Color(0xFF6930C3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7400B8).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Feature coming soon! Task collections are created automatically from your sessions.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  backgroundColor: const Color(0xFF5E60CE),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            borderRadius: BorderRadius.circular(30),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 2),
    );
  }

  // New section header builder with count badge
  Widget _buildSectionHeader(String title, IconData icon, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6930C3), Color(0xFF5E60CE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6930C3).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7400B8), Color(0xFF6930C3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7400B8).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced progress card with better visuals
  Widget _buildEnhancedProgressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7400B8), Color(0xFF5E60CE)],
          stops: [0.2, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7400B8).withOpacity(0.3),
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
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Progress",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress > 0.7
                        ? "Almost there!"
                        : progress > 0.3
                            ? "You're doing great!"
                            : "Just getting started!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Enhanced progress bar with animations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        // Background
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Progress with gradient
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutQuint,
                          height: 14,
                          width: MediaQuery.of(context).size.width *
                              0.65 *
                              progress,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0AAFF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      // horizontal spacing
                      spacing: 8,
                      // vertical spacing if it wraps
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Percentage with icon
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${(progress * 100).toInt()}% Complete",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Collection count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${taskGroups.length} Collections",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              const SizedBox(width: 24),

              // Enhanced pie chart progress indicator
              _buildEnhancedProgressChart(progress),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced pie chart with better visuals and smoother design
  Widget _buildEnhancedProgressChart(double progress) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clean circular background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
          ),

          // Improved pie chart with better styling
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Use CustomPaint for more control over the progress circle
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: CircleProgressPainter(
                        progress: value,
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        strokeWidth: 8.0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Updated center circle with subtle gradient
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color.fromARGB(255, 230, 226, 254),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Color(0xFF6930C3),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced task groups with animations
  Widget _buildEnhancedTaskGroups() {
    if (isLoading) {
      return _buildEnhancedLoadingState();
    } else if (errorMessage != null) {
      return _buildEnhancedErrorState();
    } else if (taskGroups.isEmpty) {
      return _buildEnhancedEmptyState();
    } else {
      return Column(
        children: taskGroups.asMap().entries.map((entry) {
          int index = entry.key;
          TaskGroup group = entry.value;
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 400 + (index * 70)),
            curve: Curves.easeOut,
            child: AnimatedPadding(
              padding: EdgeInsets.only(top: 0, left: 0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutQuint,
              child: _buildEnhancedTaskGroupCard(group, index),
            ),
          );
        }).toList(),
      );
    }
  }

  // Enhanced task group card with better visuals and less purple dominance
  Widget _buildEnhancedTaskGroupCard(TaskGroup taskGroup, int index) {
    final theme = _getCardTheme(taskGroup.title);

    // Add slight delay to each card for staggered effect
    Future.delayed(Duration(milliseconds: 200 * index));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToTaskDetail(taskGroup),
            splashColor: theme['color']!.withOpacity(0.1),
            highlightColor: theme['color']!.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Enhanced icon with subtle background
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: theme['color']!.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        theme['icon'] as IconData,
                        color: theme['color'],
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content column with better typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskGroup.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${taskGroup.taskCount} tasks",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Enhanced progress indicator with animation
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              // Background
                              Container(
                                height: 8,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                              ),
                              // Progress with animation and subtle color
                              TweenAnimationBuilder<double>(
                                tween:
                                    Tween(begin: 0.0, end: taskGroup.progress),
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, _) {
                                  return Container(
                                    height: 8,
                                    width: MediaQuery.of(context).size.width *
                                        0.55 *
                                        value,
                                    decoration: BoxDecoration(
                                      color: theme['color'],
                                      boxShadow: [
                                        BoxShadow(
                                          color: (theme['color'] as Color)
                                              .withOpacity(0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Simplified circular progress indicator with percentage
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: taskGroup.progress),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circular progress
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 5,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      theme['color'] as Color),
                                ),
                              ),
                              // Center text
                              Text(
                                "${(value * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme['color'],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // Simple text button instead of styled container
                      TextButton.icon(
                        onPressed: () => _navigateToTaskDetail(taskGroup),
                        icon: Icon(
                          Icons.remove_red_eye_rounded,
                          size: 16,
                          color: theme['color'],
                        ),
                        label: Text(
                          "View",
                          style: TextStyle(
                            color: theme['color'],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced loading state with shimmer effect
  Widget _buildEnhancedLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Loading shimmer for the colored top bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
              // Loading shimmer for the card content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Loading shimmer for the icon
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Loading shimmer for the text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Loading shimmer for the progress indicator
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Enhanced error state with better visuals
  Widget _buildEnhancedErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
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
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Oops! Something went wrong",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? "Couldn't connect to the server",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _refreshTaskGroups,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7400B8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: const Color(0xFF7400B8).withOpacity(0.3),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              "Try Again",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced empty state with better visuals
  Widget _buildEnhancedEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
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
              gradient: const LinearGradient(
                colors: [Color(0xFF7400B8), Color(0xFF6930C3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7400B8).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Task Collections Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Your task collections will appear here after completing sessions",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7400B8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: const Color(0xFF7400B8).withOpacity(0.3),
            ),
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            label: const Text(
              "Go to Home",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _refreshTaskGroups,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7400B8),
              side: const BorderSide(color: Color(0xFF7400B8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Refresh",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Get theme colors and icons based on task group name
  Map<String, dynamic> _getCardTheme(String title) {
    final normalizedTitle = title.toLowerCase();

    // Updated colors to match home page session colors
    if (normalizedTitle.contains('presentation')) {
      return {
        'color': const Color(0xFF4E54C8), // Deep Blue/Purple for presentations
        'icon': Icons.slideshow_rounded,
      };
    } else if (normalizedTitle.contains('meeting')) {
      return {
        'color': const Color(0xFF00B4D8), // Cyan/Blue for meetings
        'icon': Icons.groups_rounded,
      };
    } else if (normalizedTitle.contains('project')) {
      return {
        'color': const Color(0xFFFF9F1C), // Orange for projects
        'icon': Icons.engineering_rounded,
      };
    } else if (normalizedTitle.contains('report')) {
      return {
        'color': const Color(0xFF2EC4B6), // Teal/Turquoise for reports
        'icon': Icons.description_rounded,
      };
    } else if (normalizedTitle.contains('interview')) {
      return {
        'color': const Color(0xFFE76F51), // Coral/Orange for interviews
        'icon': Icons.record_voice_over_rounded,
      };
    } else if (normalizedTitle.contains('assessment')) {
      return {
        'color': const Color(0xFFBB3E03), // Rust/Burnt Orange for assessments
        'icon': Icons.assignment_rounded,
      };
    } else if (normalizedTitle.contains('feedback')) {
      return {
        'color': const Color(0xFF9C27B0), // Purple for feedback
        'icon': Icons.feedback_rounded,
      };
    } else {
      return {
        'color': const Color(0xFF7400B8), // Default Purple
        'icon': Icons.task_alt_rounded,
      };
    }
  }
}

// Custom painter for smoother progress circle
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double startAngle = -90 * (3.14159 / 180); // Convert -90° to radians
    final double sweepAngle =
        360 * progress * (3.14159 / 180); // Convert degrees to radians

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
