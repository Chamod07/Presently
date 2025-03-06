import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/components/tasks/task_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class TaskGroupService {
  // Choose the right URL based on platform
  String get baseUrl {
    if (kIsWeb) {
      // Web uses localhost
      return 'http://localhost:8000/api/task-assign';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2
      return 'http://10.0.2.2:8000/api/task-assign';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      return 'http://localhost:8000/api/task-assign';
    } else {
      // Default for other platforms
      return 'http://localhost:8000/api/task-assign';
    }
  }

  final supabase = Supabase.instance.client;

  // Get the auth token
  String? getAuthToken() {
    return supabase.auth.currentSession?.accessToken;
  }

  // Fetch task groups from backend
  Future<List<TaskGroup>> getTaskGroups() async {
    try {
      final token = getAuthToken();

      // Choose the endpoint based on authentication status
      final endpoint =
          token != null ? '$baseUrl/report' : '$baseUrl/report/debug';
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add auth token if available
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('Using endpoint: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<TaskGroup> taskGroups = [];

        // Process each task group
        for (var item in data) {
          final reportId = item['Id'];

          // Get task count for this report
          int taskCount = 0;
          double progress = 0.0;
          List<Task> tasks = [];

          if (token != null) {
            // Only fetch additional details if authenticated
            try {
              // Get task count
              final taskCountResponse = await http.get(
                Uri.parse('$baseUrl/report/task_count?report_id=$reportId'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (taskCountResponse.statusCode == 200) {
                var taskCountData = jsonDecode(taskCountResponse.body);
                taskCount = taskCountData['taskCount'] ?? 0;
              }

              // Get progress percentage
              final progressResponse = await http.get(
                Uri.parse('$baseUrl/report/progress?report_id=$reportId'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (progressResponse.statusCode == 200) {
                var progressData = jsonDecode(progressResponse.body);
                progress = (progressData['progressPercentage'] ?? 0.0) / 100;
              }

              // Get tasks
              final tasksResponse = await http.get(
                Uri.parse('$baseUrl/report/task/all?report_id=$reportId'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (tasksResponse.statusCode == 200) {
                var tasksData = jsonDecode(tasksResponse.body);
                List<dynamic> tasksList = tasksData['tasks'] ?? [];
                tasks = tasksList
                    .map((task) => Task(
                          title: task['title'] ?? "",
                          isCompleted: task['isDone'] ?? false,
                        ))
                    .toList();
              }
            } catch (e) {
              print('Error fetching details for report $reportId: $e');
            }
          } else {
            // Use mock data if not authenticated
            taskCount = 5;
            progress = 0.5;
            tasks = [
              Task(title: "Sample Task 1", isCompleted: true),
              Task(title: "Sample Task 2", isCompleted: false),
            ];
          }

          taskGroups.add(TaskGroup(
            title: item['Topic'] ?? "Untitled Group",
            taskCount: taskCount,
            progress: progress,
            tasks: tasks,
            reportId: reportId,
          ));
        }

        return taskGroups;
      } else {
        print('Error from server: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching task groups: $e');
      // Return mock data instead of throwing an exception
      return _getMockTaskGroups();
    }
  }

  // Method to provide mock data
  List<TaskGroup> _getMockTaskGroups() {
    print('Returning mock task groups');
    return [
      TaskGroup(
        title: "Machine Learning (Mock)",
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
        title: "Psychology Traits (Mock)",
        taskCount: 6,
        progress: 0.50,
        tasks: [
          Task(title: "Confidence Builder", isCompleted: true),
          Task(title: "Eye Contact Master", isCompleted: false),
          Task(title: "Voice Projection", isCompleted: false),
          Task(title: "Audience Engagement", isCompleted: false),
          Task(title: "Gesture Control", isCompleted: false),
          Task(title: "Pacing Practice", isCompleted: false),
        ],
      ),
      TaskGroup(
        title: "Development Behavior (Mock)",
        taskCount: 5,
        progress: 0.40,
        tasks: [
          Task(title: "Structure Planning", isCompleted: true),
          Task(title: "Opening Hook", isCompleted: false),
          Task(title: "Closing Impact", isCompleted: false),
          Task(title: "Visual Aid Mastery", isCompleted: false),
          Task(title: "Q&A Preparation", isCompleted: false),
        ],
      ),
    ];
  }

  Future<List<Task>> getTasksForGroup(String reportId) async {
    try {
      final token = getAuthToken();
      if (token == null) {
        return _getMockTasksForGroup();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/report/task/all?report_id=$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> tasksList = data['tasks'] ?? [];
        return tasksList
            .map((task) => Task(
                  title: task['title'] ?? "",
                  isCompleted: task['isDone'] ?? false,
                ))
            .toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return _getMockTasksForGroup();
    }
  }

  List<Task> _getMockTasksForGroup() {
    return [
      Task(title: "Mock Task 1", isCompleted: true),
      Task(title: "Mock Task 2", isCompleted: false),
      Task(title: "Mock Task 3", isCompleted: false),
    ];
  }

  Future<bool> updateTaskStatus(
      String reportId, String taskId, bool isCompleted) async {
    try {
      final token = getAuthToken();
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/report/task/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reportId': reportId,
          'taskId': taskId,
          'isDone': isCompleted,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }
}
