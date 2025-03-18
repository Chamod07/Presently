import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'What is Presently?',
      'answer':
          'Presently is an app designed to help you improve your presentation skills through practice scenarios, feedback, and tracking your progress over time.'
    },
    {
      'question': 'How does Presently work?',
      'answer':
          'Presently uses AI technology along with the device camera and microphone to analyze your presentation skills. You can practice scenarios, receive feedback, and track your progress over time.',
    },
    {
      'question': 'How do I start a practice session?',
      'answer':
          'From the home page, tap "Start Session" and select a scenario to begin practicing.'
    },
    {
      'question': 'What metrics does Presently track?',
      'answer':
          'Presently tracks various aspects of your presentation including pace of speech, vocal clarity, filler word usage, body language, eye contact, and engagement level. These metrics are used to provide personalized feedback.'
    },
    {
      'question': 'Is my data secure?',
      'answer':
          'Yes, we take privacy seriously. Your video recordings and speech data are processed securely and not shared with third parties. You can delete your data at any time through the settings menu.'
    },
    {
      'question': 'Can I use Presently without internet?',
      'answer':
          'Some basic features work offline, but for full AI analysis capabilities, an internet connection is required for processing your presentation data.'
    },
    {
      'question': 'How do I view my progress over time?',
      'answer':
          'Go to the "Progress" tab on the main navigation bar to see graphs and statistics showing your improvement across different presentation skills and metrics.'
    },
    {
      'question': 'Can I customize the presentation scenarios?',
      'answer':
          'Yes, in the "Scenarios" section, you can create custom scenarios with specific time limits, topics, and audience types to practice for your real-world presentations.'
    },
    {
      'question': 'Are there any subscription options?',
      'answer':
          'Presently offers both free and premium tiers. The premium subscription unlocks advanced analytics, unlimited practice sessions, and specialized scenario templates for different industries.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // Subtle elevation
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF9F9F9), // Very light grey background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Find answers to common questions about using Presently.',
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Roboto',
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                itemCount: faqItems.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent, // Removes the divider
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        childrenPadding: EdgeInsets.only(bottom: 16.0),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        title: Text(
                          faqItems[index]['question']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                            fontSize: 16.0,
                          ),
                        ),
                        iconColor: Theme.of(context).primaryColor,
                        collapsedIconColor: Colors.grey[600],
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                            color: Colors.grey[200],
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
                            child: Text(
                              faqItems[index]['answer']!,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 15.0,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
