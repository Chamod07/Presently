import 'package:flutter/material.dart';
import 'task_group.dart'; // Import Task model

class InfoCard extends StatelessWidget {
  final Task? task;
  final TaskGroup? taskGroup;

  const InfoCard({super.key, this.task, this.taskGroup});

  @override
  Widget build(BuildContext context) {
    // No API calls, just use the data passed in via constructor
    final String taskTitle = task?.title ?? 'Task title';
    final String groupTitle = taskGroup?.title ?? 'Task group name';
    final String description = task?.description ?? 'No description available';
    final int points = task?.points ?? 0;
    final int durationSeconds = task?.durationSeconds ?? 30;
    final List<String> instructions =
        task?.instructions ?? ['No instructions available'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(children: [
                  Text(
                    taskTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                  ),
                  Text(
                    groupTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontFamily: 'Roboto'),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'SDGP Project Presentation',
                    style: TextStyle(
                        fontSize: 17, color: Colors.grey, fontFamily: 'Roboto'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "$points Points",
                          style: TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          "Duration: ${durationSeconds} sec",
                          style: TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),

              SizedBox(height: 20),
              Text(
                "Description",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey, fontFamily: 'Roboto'),
              ),
              SizedBox(height: 20),
              Text(
                "Instructions",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto'),
              ),
              SizedBox(height: 5),
              // Display dynamic instructions list
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  instructions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      "${index + 1}. ${instructions[index]}",
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontFamily: 'Roboto'),
                    ),
                  ),
                ),
              ),
              Spacer(),
              // Add status indicator for completed tasks
              if (task != null && task!.isCompleted)
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Completed",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/camera');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7400B8),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Center(
                    child: Text(
                  task != null && task!.isCompleted
                      ? "Try again"
                      : "Start now!",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
