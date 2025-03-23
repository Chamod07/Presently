class TaskGroup {
  final String title;
  final int taskCount;
  final double progress;
  final List<Task> tasks; // List of tasks in the group
  final String? reportId; // Add reportId for API calls

  TaskGroup({
    required this.title,
    required this.taskCount,
    required this.progress,
    required this.tasks,
    this.reportId,
  });
}

class Task {
  final String title;
  bool isCompleted;
  final String? description;
  final List<String>? instructions;
  final int? points;
  final int? durationSeconds;

  Task(
      {required this.title,
      this.isCompleted = false,
      this.description,
      this.instructions,
      this.points,
      this.durationSeconds});
}
