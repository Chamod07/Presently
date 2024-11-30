// task_group.dart
class TaskGroup {
  final String title;
  final int taskCount;
  final double progress;
  final List<Task> tasks; // List of tasks in the group

  TaskGroup({
    required this.title,
    required this.taskCount,
    required this.progress,
    required this.tasks,
  });
}

class Task {
  final String title;
   bool isCompleted;

  Task({required this.title,  this.isCompleted =false});
}
