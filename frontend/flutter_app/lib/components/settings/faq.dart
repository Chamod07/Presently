import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'What is Presently?',
      'answer': 'Presently is an app designed to help you improve your presentation skills through practice scenarios, feedback, and tracking your progress over time.'
    },
    {
      'question': 'How do I start a practice session?',
      'answer': 'From the home page, tap "Start Session" and select a scenario to begin practicing.'
    },
    // Add more FAQ items
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frequently Asked Questions', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(
              faqItems[index]['question']!,
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(faqItems[index]['answer']!,
                style: TextStyle(fontFamily: 'Roboto')),
              ),
            ],
          );
        },
      ),
    );
  }
}