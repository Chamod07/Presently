import 'package:flutter/material.dart';

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy Policy',
            style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF7400B8),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF7400B8),
                tabs: [
                  Tab(text: 'Terms of Service'),
                  Tab(text: 'Privacy Policy'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTermsOfService(),
                  _buildPrivacyPolicy(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsOfService() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            'Last Updated: March 24, 2025',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 24.0),
          Text(
            '1. Acceptance of Terms',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'By accessing or using Presently, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '2. Description of Service',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Presently is an application designed to help users improve their presentation skills through practice scenarios, feedback, and progress tracking.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '3. User Accounts',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'You may be required to create an account to access certain features. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '4. User Content',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'You retain ownership of any content you submit to Presently. By submitting content, you grant Presently a non-exclusive license to use, store, and process that content for the purpose of providing and improving the service.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '5. Limitation of Liability',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Presently and its creators shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your access to or use of, or inability to access or use, the service.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '6. Changes to Terms',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We reserve the right to modify these terms at any time. We will provide notice of significant changes through the application or by other means.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 16.0),
          Text(
            'Last Updated: March 24, 2025',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 24.0),
          Text(
            '1. Information We Collect',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We collect information you provide directly, such as account information, presentation content, and feedback responses. We also collect usage data to improve our services.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '2. How We Use Your Information',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We use your information to provide and improve the Presently service, personalize your experience, analyze usage patterns, and communicate with you about the service.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '3. Data Security',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We implement reasonable security measures to protect your personal information from unauthorized access, disclosure, alteration, or destruction.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '4. Data Sharing',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We do not sell your personal information. We may share data with service providers who assist in operating our service, but they are obligated to keep your information confidential.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '5. Your Choices',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'You can access, update, or delete your account information through the app settings. You can also choose to disable certain data collection features.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          SizedBox(height: 16.0),
          Text(
            '6. Changes to This Policy',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or by other means.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ],
      ),
    );
  }
}
