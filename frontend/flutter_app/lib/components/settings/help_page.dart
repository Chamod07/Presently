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
        title: const Text(
          'Help',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
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
        ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7400B8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7400B8),
                    size: 28.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          fontFamily: 'Roboto',
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14.0,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: ExpansionTile(
                  title: Text(
                    item['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16.0,
                      fontFamily: 'Roboto',
                      color: Color(0xFF333333),
                    ),
                  ),
                  subtitle: Text(
                    item['summary'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.0,
                      color: Color(0xFF666666),
                    ),
                  ),
                  tilePadding: const EdgeInsets.all(16.0),
                  iconColor: const Color(0xFF7400B8),
                  collapsedIconColor: Colors.grey[600],
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      child: Text(
                        item['detail'],
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15.0,
                          height: 1.5,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
