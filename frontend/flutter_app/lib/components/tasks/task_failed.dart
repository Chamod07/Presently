import 'package:flutter/material.dart';

class TaskFailed extends StatelessWidget {
  const TaskFailed({super.key});
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
                  'images/Task_failed.png',
                ),
                Text(
                  'Try Again!',
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  'Try to meet all the requirements',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Roboto',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                  backgroundColor: Color(0xFF7400B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                  child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                ),
                ),
              ],
            ),
          ),
        ),
        );
  }
}