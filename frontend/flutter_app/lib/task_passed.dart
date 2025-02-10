import 'package:flutter/material.dart';

class TaskPassed extends StatelessWidget {
  const TaskPassed({super.key});
  @override
  Widget build(BuildContext context) {
    //getting screen resolutions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child:
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/Task_Pass.png',
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