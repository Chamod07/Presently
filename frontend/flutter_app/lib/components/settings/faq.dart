import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'What is Presently?',
      'answer':
          'Presently is an AI-powered app designed to help you improve your presentation and speaking skills through guided practice, real-time feedback, and detailed analytics. It\'s particularly useful for students, graduates, and young professionals who want to enhance their communication abilities for academic or career advancement.'
    },
    {
      'question': 'How does Presently improve my speaking skills?',
      'answer':
          'Presently analyzes your practice presentations using AI to provide feedback on grammar, content relevance, delivery pace, clarity, and more. The app tracks your progress over time, identifies specific areas for improvement, and offers personalized recommendations to help you become a more effective speaker.'
    },
    {
      'question': 'How do I start a practice session?',
      'answer':
          'From the home page, tap "Start Session" and select a scenario that matches your goals. You can choose from various categories such as job interviews, academic presentations, sales pitches, and more. Once you select a scenario, tap "Begin" and start speaking. The app will record and analyze your presentation.'
    },
    {
      'question': 'What kinds of feedback will I receive?',
      'answer':
          'After completing a practice session, you\'ll receive comprehensive feedback including: an overall score, detailed grammar analysis, content relevance assessment, clarity and coherence evaluation, word choice suggestions, and specific examples from your presentation with actionable improvement tips.'
    },
    {
      'question': 'Can I track my progress over time?',
      'answer':
          'Yes! Presently\'s analytics feature allows you to track your improvement across multiple practice sessions. You can view your progress in specific areas such as grammar, content relevance, and delivery, and identify trends to focus your practice efforts where they\'ll have the most impact.'
    },
    {
      'question': 'Is my data private and secure?',
      'answer':
          'Yes, we take your privacy very seriously. Your presentation recordings and data are securely stored and are not shared with third parties. You can review our full privacy policy in the app under Settings > Terms & Privacy Policy.'
    },
    {
      'question': 'Do I need an internet connection to use Presently?',
      'answer':
          'Yes, Presently requires an internet connection to analyze your presentations since the analysis is performed using cloud-based AI technology. However, you can record presentations offline and they\'ll be analyzed once you reconnect to the internet.'
    },
    {
      'question': 'How accurate is the AI analysis?',
      'answer':
          'Our AI analysis technology is highly advanced and continuously improving. It provides valuable insights that are comparable to human feedback in many aspects. However, like all AI systems, it may occasionally misinterpret certain speech patterns or specialized terminology. We recommend using the feedback as a helpful guide rather than absolute truth.'
    },
    {
      'question': 'Can I use Presently in languages other than English?',
      'answer':
          'Currently, Presently is optimized for English language presentations. We\'re working on adding support for additional languages in future updates.'
    },
    {
      'question': 'How can I provide feedback about the app?',
      'answer':
          'We welcome your feedback! You can contact our support team through the app by going to Settings > Contact Support, or by emailing us directly at chamodkarunathilake@gmail.com.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frequently Asked Questions',
            style: TextStyle(fontFamily: 'Roboto')),
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
