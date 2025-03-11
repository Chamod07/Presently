import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7400B8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Presently',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),
            const Text(
              'About This App',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Presently is an AI-powered application designed to help students, graduates, and young professionals develop and improve their speaking and presentation skills. Our mission is to make professional skill development accessible, engaging, and effective through personalized feedback and guided practice.',
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            _buildFeature(
              icon: Icons.mic,
              title: 'Practice Sessions',
              description:
                  'Realistic scenarios to practice presentations in a safe environment',
            ),
            _buildFeature(
              icon: Icons.analytics_outlined,
              title: 'AI Analysis',
              description:
                  'Detailed feedback on grammar, content relevance, and delivery',
            ),
            _buildFeature(
              icon: Icons.timeline,
              title: 'Progress Tracking',
              description: 'Monitor your improvement over time with analytics',
            ),
            _buildFeature(
              icon: Icons.tips_and_updates,
              title: 'Personalized Tips',
              description:
                  'Get customized recommendations to enhance your skills',
            ),
            _buildFeature(
              icon: Icons.history,
              title: 'Session History',
              description:
                  'Review past presentations and compare your progress',
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'For any inquiries or feedback, please contact us:',
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16.0),
            _buildContactItem(
              context,
              icon: Icons.email,
              title: 'Email',
              detail: 'presently.coach@gmail.com',
              onTap: () => _launchUrl('mailto:presently.coach@gmail.com'),
            ),
            _buildContactItem(
              context,
              icon: Icons.public,
              title: 'Website',
              detail: 'presentlyai.live',
              onTap: () => _launchUrl('https://www.presentlyai.live/'),
            ),
            _buildContactItem(
              context,
              icon: Icons.business,
              title: 'LinkedIn',
              detail: 'linkedin.com/in/presently-app/',
              onTap: () =>
                  _launchUrl('https://www.linkedin.com/in/presently-app/'),
            ),
            _buildContactItem(
              context,
              icon: Icons.chat,
              title: 'Instagram',
              detail: 'instagram.com/presently_app/',
              onTap: () =>
                  _launchUrl('https://www.instagram.com/presently_app/'),
            ),
            const SizedBox(height: 24.0),
            Center(
              child: Text(
                '© ${DateTime.now().year} Presently. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.0,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(
      {required IconData icon,
      required String title,
      required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E0F0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7400B8),
              size: 24.0,
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
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7400B8), size: 24.0),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color(0xFF7400B8),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }
}
