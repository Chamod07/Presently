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
      print('Response body: ${response.body}'); // Debug the actual response

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print('Number of task groups from API: ${data.length}');

        List<TaskGroup> taskGroups = [];

        // Process each task group from the API response directly
        for (var item in data) {
          final reportId = item['Id'];

          if (token != null) {
            // Use the new consolidated API endpoint
            try {
              final taskGroupDetails = await getTaskGroupDetails(reportId);
              print('Details for report $reportId: $taskGroupDetails');

              // Convert tasks from API response format to Task objects
              List<dynamic> allTasks = taskGroupDetails['tasks']['all'] ?? [];
              List<Task> tasks = allTasks
                  .map((task) => Task(
                        title: task['title'] ?? "",
                        isCompleted: task['isDone'] ?? false,
                      ))
                  .toList();

              taskGroups.add(TaskGroup(
                title: taskGroupDetails['session_name'] ?? "Untitled Group",
                taskCount: taskGroupDetails['taskCount'] ?? 0,
                progress: (taskGroupDetails['progress'] ?? 0.0) / 100,
                tasks: tasks,
                reportId: reportId,
              ));
            } catch (e) {
              print('Error fetching details for report $reportId: $e');
            }
          } else {
            // When not authenticated, just add basic info
            taskGroups.add(TaskGroup(
              title: item['Topic'] ?? "Untitled Group",
              taskCount: 0,
              progress: 0.0,
              tasks: [],
              reportId: reportId,
            ));
          }
        }

        print('Final number of task groups: ${taskGroups.length}');
        return taskGroups;
      } else {
        print('Error from server: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching task groups: $e');
      throw Exception('Failed to load task groups: $e');
    }
  }

  // Get tasks for a specific group - now using the consolidated API
  Future<List<Task>> getTasksForGroup(String reportId) async {
    try {
      print('TaskGroupService: Fetching tasks for report ID: $reportId');
      final token = getAuthToken();
      if (token == null) {
        print('TaskGroupService: No auth token available');
        throw Exception('Authentication required');
      }

      // Check for valid reportId
      if (reportId.isEmpty) {
        print('TaskGroupService: Empty reportId provided');
        throw Exception('Invalid report ID');
      }

      // Use the new consolidated endpoint
      print('TaskGroupService: Getting task group details');
      final details = await getTaskGroupDetails(reportId);

      print('TaskGroupService: Parsing tasks from details');
      List<dynamic> tasksList = details['tasks']['all'] ?? [];
      print('TaskGroupService: Found ${tasksList.length} tasks in response');

      return tasksList
          .map((task) => Task(
                title: task['title'] ?? "",
                isCompleted: task['isDone'] ?? false,
              ))
          .toList();
    } catch (e) {
      print('TaskGroupService: Error fetching tasks: $e');
      throw Exception('Failed to load tasks: $e');
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

  Future<bool> updateTaskStatus(
      String reportId, String taskId, bool isCompleted) async {
    try {
      print(
          'TaskGroupService: Updating task "$taskId" to ${isCompleted ? "completed" : "not completed"}');
      final token = getAuthToken();
      if (token == null) {
        print('TaskGroupService: No auth token available for task update');
        return false;
      }

      // Log the request being made
      print('TaskGroupService: Making API call to update task status');
      print(
          'TaskGroupService: reportId=$reportId, taskId=$taskId, isCompleted=$isCompleted');

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

      print(
          'TaskGroupService: Got status code ${response.statusCode} for task update');

      if (response.statusCode != 200) {
        print('TaskGroupService: Error response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('TaskGroupService: Exception in updateTaskStatus: $e');
      return false;
    }
  }
}
