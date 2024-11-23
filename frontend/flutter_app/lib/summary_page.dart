import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Summary"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Feedback Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text("Appeared Uneasy"),
              subtitle: Text("It seems you were uneasy during the practice."),
            ),
            ListTile(
              title: Text("Stammering"),
              subtitle: Text("You stammered during multiple sentences."),
            ),
            ListTile(
              title: Text("Limited Body Movement"),
              subtitle: Text("Try to use hand gestures to engage your audience."),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate back to tasks
                Navigator.pushNamed(context, '/tasks');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("View Suggested Tasks"),
            ),
          ],
        ),
      ),
    );
  }
}
