import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // Data structure for each help category
  final List<Map<String, dynamic>> _helpCategories = [
    {
      'title': 'Getting Started',
      'description': 'Learn the basics of using Presently',
      'icon': Icons.play_circle_outline,
      'items': [
        {
          'title': 'Creating Your Account',
          'summary': 'Learn how to sign up and set up your profile',
          'detail':
              'To create an account, download the Presently app and tap "Sign Up" on the welcome screen. Follow the prompts to enter your email, create a password, and complete your profile information.',
          'isExpanded': false,
        },
        {
          'title': 'Navigating the App',
          'summary': 'Understanding the main sections of Presently',
          'detail':
              'The app has four main sections: Home (access practice sessions), History (view past sessions), Analytics (track progress), and Settings (manage your account).',
          'isExpanded': false,
        },
        {
          'title': 'Your First Practice Session',
          'summary': 'How to start and complete a practice session',
          'detail':
              'From the Home screen, tap "Start Session" and choose a scenario. When ready, tap "Begin" and start speaking. The app will record your presentation and provide analysis when you finish.',
          'isExpanded': false,
        },
      ],
    },
    {
      'title': 'Practice Sessions',
      'description': 'Make the most of your practice',
      'icon': Icons.mic,
      'items': [
        {
          'title': 'Choosing Scenarios',
          'summary': 'Finding the right practice material',
          'detail':
              'Browse through various categories or use the search function to find relevant scenarios for your needs. You can also create custom scenarios from the Home screen.',
          'isExpanded': false,
        },
        {
          'title': 'Understanding Feedback',
          'summary': 'How to interpret your analysis results',
          'detail':
              'After each session, you\'ll receive feedback on grammar, content relevance, clarity, and other aspects. Each category has a score and specific recommendations for improvement.',
          'isExpanded': false,
        },
        {
          'title': 'Saving and Sharing',
          'summary': 'Managing your practice recordings',
          'detail':
              'You can save important sessions for later review. From the session results screen, tap the save icon. To share your results, use the share button to export as PDF or send to colleagues.',
          'isExpanded': false,
        },
      ],
    },
    {
      'title': 'Account Management',
      'description': 'Manage your Presently account',
      'icon': Icons.person,
      'items': [
        {
          'title': 'Updating Profile Information',
          'summary': 'How to change your personal details',
          'detail':
              'Go to Settings and tap on your profile information at the top. You can edit your name, role, and profile picture by tapping the edit icon.',
          'isExpanded': false,
        },
        {
          'title': 'Changing Password',
          'summary': 'Steps to update your password',
          'detail':
              'In Settings, go to "Account" and tap "Change Password." You\'ll need to enter your current password and then create and confirm a new password.',
          'isExpanded': false,
        },
        {
          'title': 'Subscription Management',
          'summary': 'Managing your premium features',
          'detail':
              'Access subscription details in Settings under "Account." Here you can upgrade your plan, manage payment methods, or cancel auto-renewal.',
          'isExpanded': false,
        },
      ],
    },
    {
      'title': 'Troubleshooting',
      'description': 'Fix common issues',
      'icon': Icons.build,
      'items': [
        {
          'title': 'Audio Problems',
          'summary': 'Issues with microphone or playback',
          'detail':
              'Make sure you\'ve granted microphone permissions to the app. If audio is still not working, try restarting the app or checking your device settings.',
          'isExpanded': false,
        },
        {
          'title': 'App Performance',
          'summary': 'Dealing with slow performance or crashes',
          'detail':
              'Ensure your app is updated to the latest version. You can also try clearing the cache in your device settings or reinstalling the app if problems persist.',
          'isExpanded': false,
        },
        {
          'title': 'Data Synchronization',
          'summary': 'Problems with missing data',
          'detail':
              'If your data isn\'t syncing properly, check your internet connection. You can manually sync by pulling down on the main screen to refresh.',
          'isExpanded': false,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
      ),
      body: ListView.builder(
        itemCount: _helpCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = _helpCategories[categoryIndex];
          return _buildHelpSection(
            context,
            category['title'],
            category['description'],
            category['icon'],
            category['items'],
            categoryIndex,
          );
        },
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    List<dynamic> items,
    int categoryIndex,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                fontFamily: 'Roboto',
              ),
            ),
            subtitle: Text(
              description,
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            leading: Icon(
              icon,
              color: const Color(0xFF7400B8),
              size: 36.0,
            ),
          ),
          ExpansionPanelList(
            expandedHeaderPadding: EdgeInsets.zero,
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _helpCategories[categoryIndex]['items'][index]['isExpanded'] =
                    !isExpanded;
              });
            },
            children: items.asMap().entries.map<ExpansionPanel>((entry) {
              final int index = entry.key;
              final Map<String, dynamic> item = entry.value;
              return ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    subtitle: Text(
                      item['summary'],
                      style: const TextStyle(fontFamily: 'Roboto'),
                    ),
                  );
                },
                body: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    item['detail'],
                    style: const TextStyle(fontFamily: 'Roboto'),
                  ),
                ),
                isExpanded: item['isExpanded'],
                canTapOnHeader: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
