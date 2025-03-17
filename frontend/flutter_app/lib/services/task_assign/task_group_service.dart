import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/components/tasks/task_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_app/services/api_client.dart';

class TaskGroupService {
  final ApiClient _apiClient = ApiClient();

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

  // Fetch detailed information for a specific task group
  Future<Map<String, dynamic>> getTaskGroupDetails(String reportId) async {
    try {
      final token = getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/report/details?report_id=$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status for details: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error from server: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching task group details: $e');
      throw Exception('Failed to fetch task group details: $e');
    }
  }

  // Fetch task groups from backend
  Future<List<TaskGroup>> getTaskGroups() async {
    try {
      final response = await _apiClient.get('/task-assign/report');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Create basic task groups
        List<TaskGroup> taskGroups = data.map((item) {
          final String reportId = item['Id'] ?? '';
          final String topic = item['Topic'] ?? '';

          return TaskGroup(
            title: topic,
            reportId: reportId,
            taskCount: 0, // Placeholder value
            progress: 0.0, // Placeholder value
            tasks: [], // Placeholder value
          );
        }).toList();

        // Fetch details for each task group to get accurate progress
        for (int i = 0; i < taskGroups.length; i++) {
          if (taskGroups[i].reportId != null) {
            try {
              final details =
                  await getTaskGroupDetails(taskGroups[i].reportId!);
              final progress =
                  details['progress'] / 100.0; // Convert percentage to decimal
              final taskCount = details['taskCount'] ?? 0;

              // Get the tasks data from the details
              final tasksList = details['tasks']['all'] as List<dynamic>;
              final List<Task> tasks = tasksList.map((task) {
                return Task(
                  title: task['title'] ?? '',
                  isCompleted: task['isDone'] ?? false,
                  description: task['description'],
                  instructions: task['instructions'] != null
                      ? List<String>.from(task['instructions'])
                      : [],
                  points: task['points'],
                  durationSeconds:
                      task['duration'], // Note: using 'duration' from backend
                );
              }).toList();

              // Update the task group with accurate data and tasks
              taskGroups[i] = TaskGroup(
                title: taskGroups[i].title,
                reportId: taskGroups[i].reportId,
                taskCount: taskCount,
                progress: progress,
                tasks: tasks, // Now populated with actual tasks
              );
            } catch (e) {
              print(
                  'Error fetching details for task group ${taskGroups[i].reportId}: $e');
              // Keep the placeholder values if we can't fetch details
            }
          }
        }

        return taskGroups;
      } else {
        throw Exception('Failed to load task groups: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch task groups: $e');
    }
  }

  // Get tasks for a specific group using the new endpoint
  Future<List<Task>> getTasksForGroup(String reportId) async {
    try {
      final response = await _apiClient
          .get('/task-assign/report/details?report_id=$reportId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasks = data['tasks']['all'] as List<dynamic>;

        return tasks.map((task) {
          return Task(
            title: task['title'] ?? '',
            isCompleted: task['isDone'] ?? false,
            description: task['description'],
            instructions: task['instructions'] != null
                ? List<String>.from(task['instructions'])
                : [],
            points: task['points'],
            durationSeconds:
                task['duration'], // Changed to match backend field name
          );
        }).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get todo tasks for a specific group
  Future<List<Task>> getTodoTasksForGroup(String reportId) async {
    try {
      final token = getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Use the new consolidated endpoint
      final details = await getTaskGroupDetails(reportId);
      List<dynamic> tasksList = details['tasks']['todo'] ?? [];

      return tasksList
          .map((task) => Task(
                title: task['title'] ?? "",
                isCompleted: false,
              ))
          .toList();
    } catch (e) {
      print('Error fetching todo tasks: $e');
      throw Exception('Failed to load todo tasks: $e');
    }
  }

  // Get completed tasks for a specific group
  Future<List<Task>> getCompletedTasksForGroup(String reportId) async {
    try {
      final token = getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Use the new consolidated endpoint
      final details = await getTaskGroupDetails(reportId);
      List<dynamic> tasksList = details['tasks']['completed'] ?? [];

      return tasksList
          .map((task) => Task(
                title: task['title'] ?? "",
                isCompleted: true,
              ))
          .toList();
    } catch (e) {
      print('Error fetching completed tasks: $e');
      throw Exception('Failed to load completed tasks: $e');
    }
  }

  Future<void> updateTaskStatus(
      String reportId, String taskId, bool isCompleted) async {
    try {
      await _apiClient.post(
        '/task-assign/update-task-status',
        body: {
          'reportId': reportId,
          'taskId': taskId,
          'isCompleted': isCompleted,
        },
      );
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  // Fetch overall progress directly from the backend
  Future<double> getOverallProgress() async {
    try {
      final response = await _apiClient.get('/task-assign/overall-progress');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['overallProgressPercentage'] ?? 0.0) /
            100.0; // Convert to decimal
      } else {
        throw Exception(
            'Failed to load overall progress: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch overall progress: $e');
    }
  }
}
