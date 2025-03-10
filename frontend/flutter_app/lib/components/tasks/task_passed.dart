import 'package:flutter/material.dart';
import 'package:flutter_app/utils/image_utils.dart'; // Add this import

class TaskPassed extends StatelessWidget {
  const TaskPassed({super.key});
  @override
  Widget build(BuildContext context) {
    //getting screen resolutions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/Task_Pass.png',
              ),
              CircleAvatar(
                radius: 20, // Adjust size as needed
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  color: Colors.grey[700],
                  size: 20, // Adjust size as needed
                ),
              ),
              Text(
                'Task Completed!',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Roboto',
                ),
              ),
              Text(
                'Great job! Keep practicing!',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
