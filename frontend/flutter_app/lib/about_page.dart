import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
            const Text(
              'About This App',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'This app was developed to help students, graduates and young professionals improve on their speaking and presentation skills, a vital soft skill needed by most hiring companies',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Features:',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const ListTile(
              leading: Icon(Icons.check),
              title: Text('Feature 1'),
            ),
            const ListTile(
              leading: Icon(Icons.check),
              title: Text('Feature 2'),
            ),
            const ListTile(
              leading: Icon(Icons.check),
              title: Text('Feature 3'),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'For any inquiries or feedback, please contact:',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'LinkedIn: https://www.linkedin.com/in/presently-app-7a6781337/\n\n'
                  'Website: https://udom1xb9nhetfp3d.vercel.app/\n',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}