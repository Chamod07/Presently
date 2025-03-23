import 'package:flutter_app/components/tasks/task_group.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';

class TaskGroupService {
  final SupabaseService _supabaseService = SupabaseService();

  // Get the auth token
  String? getAuthToken() {
    return _supabaseService.currentSession?.accessToken;
  }

  // Get the current user ID
  String? get currentUserId => _supabaseService.currentUserId;

  // Fetch task groups directly from Supabase
  Future<List<TaskGroup>> getTaskGroups() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('TaskGroupService: No user ID available');
        return [];
      }

      debugPrint('TaskGroupService: Fetching task groups for user: $userId');

      // Query UserReport table which contains the report data
      final response = await _supabaseService.client
          .from('UserReport')
          .select('reportId, session_name')
          .eq('userId', userId)
          .order('createdAt', ascending: false);

      debugPrint('TaskGroupService received ${response.length} task groups');

      List<TaskGroup> taskGroups = [];

      for (final item in response) {
        // Get the report ID
        final reportId = item['reportId'] as String;
        final sessionName = item['session_name'] ?? "Untitled Session";

        // Get tasks and progress data for this report
        final details = await getTaskGroupDetails(reportId);
        final progress = details['progress'] as double? ?? 0.0;
        final taskCount = details['taskCount'] as int? ?? 0;

        // Create TaskGroup object
        final taskGroup = TaskGroup(
          title: sessionName,
          taskCount: taskCount,
          progress: progress / 100, // Convert percentage to 0-1 scale
          tasks: [], // We'll fetch tasks separately
          reportId: reportId,
        );

        // Fetch tasks for this group
        final tasks = await getTasksForGroup(reportId);
        taskGroup.tasks.addAll(tasks);

        taskGroups.add(taskGroup);
      }

      return taskGroups;
    } catch (e) {
      debugPrint('Error fetching task groups from Supabase: $e');
      return [];
    }
  }

  // Fetch detailed information for a specific task group
  Future<Map<String, dynamic>> getTaskGroupDetails(String reportId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Authentication required');
      }

      // Get report details from UserReport
      final reportResponse = await _supabaseService.client
          .from('UserReport')
          .select('session_name')
          .eq('reportId', reportId)
          .eq('userId', userId)
          .single();

      // Get all tasks with their status
      final tasks = await _getTasksWithStatus(reportId);

      // Calculate task counts
      final totalTasks = tasks.length;
      final completedTasks =
          tasks.where((task) => task['isDone'] == true).length;
      final pendingTasks = totalTasks - completedTasks;

      // Calculate progress percentage
      double progressPercentage = 0.0;
      if (totalTasks > 0) {
        progressPercentage = (completedTasks / totalTasks) * 100;
      }

      // Separate tasks into categories
      final todoTasks = tasks.where((task) => task['isDone'] == false).toList();
      final completedTasksList =
          tasks.where((task) => task['isDone'] == true).toList();

      return {
        'reportId': reportId,
        'session_name': reportResponse['session_name'] ?? "Untitled Session",
        'progress': progressPercentage,
        'taskCount': totalTasks,
        'completedCount': completedTasks,
        'pendingCount': pendingTasks,
        'tasks': {
          'all': tasks,
          'todo': todoTasks,
          'completed': completedTasksList,
        }
      };
    } catch (e) {
      debugPrint('Error fetching task group details: $e');
      throw Exception('Failed to fetch task group details: $e');
    }
  }

  // Private helper function to get all tasks with their status
  Future<List<Map<String, dynamic>>> _getTasksWithStatus(
      String reportId) async {
    try {
      debugPrint('TaskGroupService: Fetching tasks for report ID: $reportId');

      // Get challenge IDs and isDone status linked to the reportId
      final taskGroupResponse = await _supabaseService.client
          .from('TaskGroupChallenges')
          .select('challengeId, isDone')
          .eq('reportId', reportId);

      debugPrint(
          'TaskGroupService: Found ${taskGroupResponse.length} challenge links');

      // Create a mapping of challengeId to its isDone status
      final Map<int, bool> challengeStatusMap = {};
      for (final item in taskGroupResponse) {
        if (item.containsKey('challengeId')) {
          challengeStatusMap[item['challengeId']] = item['isDone'] ?? false;
          debugPrint(
              'Challenge ${item['challengeId']}, isDone: ${item['isDone']}');
        }
      }

      final challengeIds = challengeStatusMap.keys.toList();
      if (challengeIds.isEmpty) {
        debugPrint(
            'TaskGroupService: No challenges found for report $reportId');
        return [];
      }

      // Fetch challenge details
      final challengesResponse = await _supabaseService.client
          .from('Challenges')
          .select('id, title, description, instructions, points, duration')
          .inFilter('id', challengeIds);

      debugPrint(
          'TaskGroupService: Found ${challengesResponse.length} challenges');

      // Debug log challenge data
      for (var challenge in challengesResponse) {
        debugPrint('Challenge: ${challenge['id']} - ${challenge['title']}');
      }

      // Combine challenge details with isDone status
      return challengesResponse.map<Map<String, dynamic>>((item) {
        final isDone = challengeStatusMap[item['id']] ?? false;
        return {
          'id': item['id'],
          'title': item['title'],
          'isDone': isDone,
          'description': item['description'] ?? '',
          'instructions': item['instructions'] ?? [],
          'points': item['points'] ?? 0,
          'duration': item['duration'] ?? 30,
        };
      }).toList();
    } catch (e) {
      debugPrint('TaskGroupService: Error in _getTasksWithStatus: $e');
      return [];
    }
  }

  // Get tasks for a specific group
  Future<List<Task>> getTasksForGroup(String reportId) async {
    try {
      if (reportId.isEmpty) {
        debugPrint('TaskGroupService: Empty reportId provided');
        return [];
      }

      // Get tasks with status from helper method
      final tasks = await _getTasksWithStatus(reportId);

      debugPrint(
          'TaskGroupService: Converting ${tasks.length} tasks to Task objects');

      // Convert to Task objects
      final taskObjects = tasks.map((task) {
        // Debug log task conversion
        debugPrint(
            'Converting task: ${task['title']}, isDone: ${task['isDone']}');

        return Task(
          title: task['title'] ?? "",
          isCompleted: task['isDone'] ?? false,
          description: task['description'],
          instructions:
              task['instructions'] != null && task['instructions'] is List
                  ? List<String>.from(task['instructions'])
                  : null,
          points: task['points'],
          durationSeconds: task['duration'],
        );
      }).toList();

      debugPrint(
          'TaskGroupService: Returning ${taskObjects.length} Task objects');
      return taskObjects;
    } catch (e) {
      debugPrint('TaskGroupService: Error fetching tasks: $e');
      return [];
    }
  }

  // Update task status in Supabase
  Future<bool> updateTaskStatus(
      String reportId, String taskId, bool isCompleted) async {
    try {
      debugPrint(
          'TaskGroupService: Updating task "$taskId" to ${isCompleted ? "completed" : "not completed"}');

      final userId = currentUserId;
      if (userId == null) {
        debugPrint('TaskGroupService: No user ID available for task update');
        return false;
      }

      // First, find the challenge ID that matches this task title
      final tasksResponse = await _getTasksWithStatus(reportId);
      final task = tasksResponse.firstWhere(
        (t) => t['title'] == taskId,
        orElse: () => {},
      );

      if (task.isEmpty || !task.containsKey('id')) {
        debugPrint('TaskGroupService: Task not found: $taskId');
        return false;
      }

      final challengeId = task['id'];

      // Update task status in TaskGroupChallenges
      final response = await _supabaseService.client
          .from('TaskGroupChallenges')
          .update({'isDone': isCompleted})
          .eq('reportId', reportId)
          .eq('challengeId', challengeId);

      debugPrint('TaskGroupService: Update completed');
      return true; // If we got here, the update was successful
    } catch (e) {
      debugPrint('TaskGroupService: Exception in updateTaskStatus: $e');
      return false;
    }
  }
}
