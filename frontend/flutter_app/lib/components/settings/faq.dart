import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'What is Presently?',
      'answer': 'Presently is an app designed to help you improve your presentation skills through practice scenarios, feedback, and tracking your progress over time.'
    },
    {
      'question': 'How does Presently work?',
      'answer': 'Presently uses AI technology along with the device camera and microphone to analyze your presentation skills. You can practice scenarios, receive feedback, and track your progress over time.',
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Find answers to common questions about using Presently.',
              style: TextStyle(fontSize: 16.0, fontFamily: 'Roboto'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ExpansionTile(
                    title: Text(
                      faqItems[index]['question']!,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          faqItems[index]['answer']!,
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}