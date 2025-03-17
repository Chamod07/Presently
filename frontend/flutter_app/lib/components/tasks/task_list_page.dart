// task_detail_page.dart
import 'package:flutter/material.dart';
import 'task_group.dart'; // Import the TaskGroup model
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/services/task_assign/task_group_service.dart';
import 'package:flutter_app/components/tasks/info_card.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskGroup taskGroup;

  const TaskDetailPage({Key? key, required this.taskGroup}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  String selectedFilter = "All";
  bool isLoading = false;
  final TaskGroupService _taskGroupService = TaskGroupService();
  List<Task> allTasks = [];
  double progress = 0.0; // Track progress separately

  @override
  void initState() {
    super.initState();
    // Start with the tasks we already have from TaskGroupPage
    allTasks = widget.taskGroup.tasks;
    // Use initial progress from task group
    progress = widget.taskGroup.progress;

    // Only call API if we don't have tasks already (as a fallback)
    if (allTasks.isEmpty) {
      _refreshTasks();
    } else {
      // No need to show loading indicator since we already have data
      isLoading = false;
    }
  }

  Future<void> _refreshTasks() async {
    // Only call this if we don't already have tasks
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.taskGroup.reportId != null) {
        // Since the TaskGroupPage already fetched the complete data
        // We can just get the tasks directly from the API without needing details
        final tasks = await _taskGroupService
            .getTasksForGroup(widget.taskGroup.reportId!);

        if (mounted) {
          setState(() {
            allTasks = tasks;
            // Calculate progress from task completion status
            if (tasks.isNotEmpty) {
              progress =
                  tasks.where((task) => task.isCompleted).length / tasks.length;
            }
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error refreshing tasks: $e');
      if (mounted) {
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
    return allTasks; // All tasks
  }

  void handleTaskTap(Task task) {
    // Navigate to InfoCard instead of toggling completion directly
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoCard(task: task, taskGroup: widget.taskGroup),
      ),
    );
  }

  void toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;

      // Update progress immediately in the UI
      if (allTasks.isNotEmpty) {
        progress =
            allTasks.where((t) => t.isCompleted).length / allTasks.length;
      }

      // Update in backend
      _taskGroupService.updateTaskStatus(
        widget.taskGroup.reportId ?? '',
        task.title, // Using title as the ID here
        task.isCompleted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/task_group_page'),
        ),
        title: Text(widget.taskGroup.title,
            style: const TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterTab("All", allTasks.length),
                _buildFilterTab("To do",
                    allTasks.where((task) => !task.isCompleted).length),
                _buildFilterTab("Completed",
                    allTasks.where((task) => task.isCompleted).length),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar - use our local progress variable instead of widget.taskGroup.progress
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: Color(0xFF7400B8),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              "Overall Progress: ${(progress * 100).toInt()}%",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // List of Tasks with loading indicator
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        Task task = filteredTasks[index];
                        return GestureDetector(
                          onTap: () => handleTaskTap(task),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: task.isCompleted
                                      ? Color(0xFF7400B8)
                                      : Colors.grey,
                                ),
                                onPressed: () => toggleTaskCompletion(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: task.isCompleted
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selectedFilter == label ? Color(0xFF2F37ED) : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selectedFilter == label
                  ? Color(0xFF7400B8)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
