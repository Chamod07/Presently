import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';

class InfoCard extends StatelessWidget {
  final String taskTitle;
  final String taskDescription;
  final String taskSubtitle;
  final int points;
  final String duration;

  const InfoCard({
    super.key,
    this.taskTitle = 'Steady Stare',
    this.taskDescription =
        'This task is to enhance your eye contact skills, which are crucial for effective communication and building rapport.',
    this.taskSubtitle = 'SDGP Project Presentation',
    this.points = 2,
    this.duration = '30 sec',
  });

  @override
  Widget build(BuildContext context) {
    // Determine theme color based on task title or subtitles
    final themeColor = _getTaskThemeColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar with Hero Animation
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: themeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 22),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                taskTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1))
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.network(
                    'https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-1.2.1&auto=format&fit=crop&w=1567&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          themeColor.withOpacity(0.3),
                          themeColor,
                        ],
                      ),
                    ),
                  ),
                  // Bottom scrim for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),

          // Enhanced Card Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Header Section with Label
                  _buildSectionHeader(
                      'Level Up', Icons.emoji_events_rounded, themeColor),

                  const SizedBox(height: 12),
                  Text(
                    taskSubtitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Enhanced Stats Cards
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        _buildEnhancedStatCard(
                          context,
                          'Points',
                          points.toString(),
                          Icons.stars_rounded,
                          const Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 16),
                        _buildEnhancedStatCard(
                          context,
                          'Duration',
                          duration,
                          Icons.timer_rounded,
                          const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  ),

                  // Description Section
                  _buildEnhancedSection(
                    'Description',
                    taskDescription,
                    icon: Icons.description_rounded,
                    color: themeColor,
                  ),

                  // Instructions Section
                  _buildEnhancedInstructionsSection(context, themeColor),

                  // Tips Section
                  _buildEnhancedSection(
                    'Tips',
                    '• Focus on maintaining natural eye contact\n• Remember to blink normally\n• Practice with different audience sizes',
                    icon: Icons.lightbulb_rounded,
                    color: const Color(0xFF2196F3),
                  ),

                  const SizedBox(height: 36),

                  // Updated Start Button with proper implementation
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startChallenge(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: themeColor.withOpacity(0.4),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.white.withOpacity(0.2);
                            }
                            return null;
                          },
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                const Icon(Icons.play_arrow_rounded, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            "Start Challenge",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add a note about the challenge
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        "Your camera and microphone will be used for this challenge",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 2),
    );
  }

  // Add a proper implementation for starting the challenge
  void _startChallenge(BuildContext context) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7400B8)),
          ),
        ),
      );

      // Simulate loading for a better UX
      Future.delayed(const Duration(milliseconds: 800), () {
        // Hide loading dialog
        Navigator.pop(context);

        // Navigate to camera screen with task data
        Navigator.pushNamed(
          context,
          '/camera',
          arguments: {
            'taskTitle': taskTitle,
            'taskDuration': duration,
            'taskType': _determineTaskType(taskTitle),
          },
        ).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start the challenge. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          print('Navigation error: $error');
        });
      });
    } catch (e) {
      Navigator.pop(context); // Hide loading dialog if shown
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to determine task type from title
  String _determineTaskType(String title) {
    final normalizedTitle = title.toLowerCase();
    if (normalizedTitle.contains('stare') || normalizedTitle.contains('eye')) {
      return 'eye_contact';
    } else if (normalizedTitle.contains('voice') ||
        normalizedTitle.contains('speak')) {
      return 'voice';
    } else if (normalizedTitle.contains('gesture') ||
        normalizedTitle.contains('body')) {
      return 'gesture';
    } else if (normalizedTitle.contains('confidence') ||
        normalizedTitle.contains('posture')) {
      return 'posture';
    } else {
      return 'general';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(BuildContext context, String label,
      String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSection(String title, String content,
      {IconData? icon, Color? color}) {
    color ??= const Color(0xFF7400B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInstructionsSection(
      BuildContext context, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checklist_rounded,
                    color: Color(0xFFE91E63), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEnhancedInstructionStep(
                  '1',
                  'Take a few deep breaths to calm your nerves.',
                  const Color(0xFFE91E63),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildEnhancedInstructionStep(
                  '2',
                  'Skim through your report to refresh your memory.',
                  const Color(0xFFE91E63),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildEnhancedInstructionStep(
                  '3',
                  'Good luck on your first challenge.',
                  const Color(0xFFE91E63),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInstructionStep(
      String number, String instruction, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTaskThemeColor() {
    final normalizedTitle = taskTitle.toLowerCase();

    if (normalizedTitle.contains('stare') || normalizedTitle.contains('eye')) {
      return const Color(0xFF7400B8); // Purple for eye contact tasks
    } else if (normalizedTitle.contains('voice') ||
        normalizedTitle.contains('speak')) {
      return const Color(0xFF2196F3); // Blue for speaking tasks
    } else if (normalizedTitle.contains('gesture') ||
        normalizedTitle.contains('body')) {
      return const Color(0xFFFF9800); // Orange for body language tasks
    } else if (normalizedTitle.contains('confidence') ||
        normalizedTitle.contains('posture')) {
      return const Color(0xFF4CAF50); // Green for confidence tasks
    } else {
      return const Color(0xFF7400B8); // Default Purple
    }
  }
}
