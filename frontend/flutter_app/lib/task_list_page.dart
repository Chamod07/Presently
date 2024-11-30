// task_detail_page.dart
import 'package:flutter/material.dart';
import 'task_group.dart'; // Import the TaskGroup model

class TaskDetailPage extends StatefulWidget {
  final TaskGroup taskGroup;

  const TaskDetailPage({Key? key, required this.taskGroup}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  String selectedFilter = "All";

  List<Task> getFilteredTasks() {
    if (selectedFilter == "To do") {
      return widget.taskGroup.tasks.where((task) => !task.isCompleted).toList();
    } else if (selectedFilter == "Completed") {
      return widget.taskGroup.tasks.where((task) => task.isCompleted).toList();
    }
    return widget.taskGroup.tasks; // All tasks
  }

  void toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
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
                _buildFilterTab("All", widget.taskGroup.tasks.length),
                _buildFilterTab(
                    "To do",
                    widget.taskGroup.tasks
                        .where((task) => !task.isCompleted)
                        .length),
                _buildFilterTab(
                    "Completed",
                    widget.taskGroup.tasks
                        .where((task) => task.isCompleted)
                        .length),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            LinearProgressIndicator(
              value: widget.taskGroup.progress,
              backgroundColor: Colors.grey.shade300,
              color: Colors.purple,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              "Overall Progress: ${(widget.taskGroup.progress * 100).toInt()}%",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // List of Tasks
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  Task task = filteredTasks[index];
                  return GestureDetector(
                    onTap: () => toggleTaskCompletion(task),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                          task.isCompleted ? Colors.purple : Colors.grey,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                            task.isCompleted ? Colors.black : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: task.isCompleted
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
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
              color: selectedFilter == label ? Colors.purple : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
              selectedFilter == label ? Colors.purple : Colors.grey.shade300,
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

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          task.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.purple : Colors.grey,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            color: task.isCompleted ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: task.isCompleted
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}
