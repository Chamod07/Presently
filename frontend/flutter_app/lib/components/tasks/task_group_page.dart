// task_group_page.dart
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

class _TaskGroupPageState extends State<TaskGroupPage> {
  File? _profileImage;
  List<TaskGroup> taskGroups = [];
  bool isLoading = true;
  String? errorMessage;
  // Add cache variables
  static List<TaskGroup> _cachedTaskGroups = [];
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadTaskGroups();
  }

  Future<void> _loadTaskGroups() async {
    // First check if we have valid cached data
    if (_cachedTaskGroups.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
      // Use cached data if it's available and still valid
      setState(() {
        taskGroups = _cachedTaskGroups;
        isLoading = false;
      });
      // Refresh in background without showing loading indicator
      _refreshTaskGroupsInBackground();
      return;
    }

    // If no valid cache, fetch data normally with loading indicator
    _fetchTaskGroups();
  }

  Future<void> _refreshTaskGroupsInBackground() async {
    try {
      final TaskGroupService service = TaskGroupService();
      final fetchedTaskGroups = await service.getTaskGroups();

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
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final TaskGroupService service = TaskGroupService();

      try {
        final fetchedTaskGroups = await service.getTaskGroups();
        if (mounted) {
          setState(() {
            taskGroups = fetchedTaskGroups;
            isLoading = false;

            // Update cache
            _cachedTaskGroups = fetchedTaskGroups;
            _lastFetchTime = DateTime.now();
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

  Widget _buildTaskGroupCard(TaskGroup taskGroup) {
    return GestureDetector(
      onTap: () {
        // Navigate to the TaskDetailPage with the selected TaskGroup
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(taskGroup: taskGroup),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
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
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: taskGroup.progress,
                      color: Colors.green,
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
        color: Color(0xFF7400B8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Your overall progress!",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                          color: Colors.grey,
                          radius: 10,
                          title: ""),
                      PieChartSectionData(
                          value: 100 - (progress * 100),
                          color: Colors.grey.shade300,
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.settings,
                  color: Colors.grey[700],
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallProgress(overallProgress),
            const SizedBox(height: 16),
            // Task Groups Header with Count Circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "Task Groups",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xFF7400B8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${taskGroups.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Add refresh button
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _fetchTaskGroups,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Task Groups List with loading indicator
            Expanded(
              child: _buildTaskGroupsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }

  Widget _buildTaskGroupsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTaskGroups,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (taskGroups.isEmpty) {
      return const Center(
        child: Text('No task groups available'),
      );
    } else {
      return ListView.builder(
        itemCount: taskGroups.length,
        itemBuilder: (context, index) {
          return _buildTaskGroupCard(taskGroups[index]);
        },
      );
    }
  }
}
