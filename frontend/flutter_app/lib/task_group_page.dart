// task_group_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'task_list_page.dart'; // Import the TaskDetailPage
import 'task_group.dart'; // Import the TaskGroup model
import 'package:flutter_app/navbar.dart';

class TaskGroupPage extends StatefulWidget {
  const TaskGroupPage({Key? key}) : super(key: key);

  @override
  _TaskGroupPageState createState() => _TaskGroupPageState();
}

class _TaskGroupPageState extends State<TaskGroupPage> {
  File? _profileImage;

  final List<TaskGroup> taskGroups = [
    TaskGroup(
      title: "Machine Learning",
      taskCount: 4,
      progress: 0.65,
      tasks: [
        Task(title: "Power Pose Challenge", isCompleted: true),
        Task(title: "Smooth Steady Stare", isCompleted: false),
        Task(title: "Smooth Talker", isCompleted: false),
        Task(title: "Filler Free Zone", isCompleted: false),
      ],
    ),
    TaskGroup(
      title: "Psychology Traits",
      taskCount: 6,
      progress: 0.50,
      tasks: [
        Task(title: " ", isCompleted: true),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
      ],
    ),
    TaskGroup(
      title: "Development Behavior",
      taskCount: 5,
      progress: 0.40,
      tasks: [
        Task(title: " ", isCompleted: true),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
        Task(title: " ", isCompleted: false),
      ],
    ),
  ];

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
    return taskGroups.fold<double>(
        0.0, (sum, group) => sum + group.progress) /
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
            onTap: _pickProfileImage,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage('assets/default_profile.png')
                as ImageProvider,
                radius: 20,
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
              mainAxisAlignment: MainAxisAlignment.start,
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
            const SizedBox(height: 16),
            // Task Groups List
            Expanded(
              child: ListView.builder(
                itemCount: taskGroups.length,
                itemBuilder: (context, index) {
                  return _buildTaskGroupCard(taskGroups[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar (selectedIndex: 0),
    );
  }
}