import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/components/summary/graph_display.dart';
import 'package:flutter_app/providers/report_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../models/report.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  int _currentPage = 0;

  // Enhanced visual styling with more distinctive colors
  final List<Map<String, dynamic>> _pageData = [
    {
      "title": "Context",
      "icon": Icons.subject,
      "color": Color(0xFF6A00F4), // Deep purple
    },
    {
      "title": "Grammar",
      "icon": Icons.spellcheck,
      "color": Color(0xFF006EE6), // Vivid blue
    },
    {
      "title": "Body Language",
      "icon": Icons.accessibility_new,
      "color": Color(0xFF00B0BA), // Teal
    },
    {
      "title": "Voice",
      "icon": Icons.mic,
      "color": Color(0xFFE94560), // Coral red
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _pageData.length,
      vsync: this,
      initialIndex: _currentPage,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentPage = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get selectedIndex and sessionName from route arguments
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int selectedIndex =
        args?['selectedIndex'] ?? 1; // Default to 1 (add/new tab)
    final String? initialSessionName = args?['sessionName'];

    // Provide the ReportProvider at this level
    return ChangeNotifierProvider(
      create: (context) {
        final provider = ReportProvider();
        // Set initial session name if provided in navigation arguments
        if (initialSessionName != null && initialSessionName.isNotEmpty) {
          provider.setSessionName(initialSessionName);
        }
        return provider;
      },
      child: _SummaryPageContent(
        pageController: _pageController,
        tabController: _tabController,
        currentPage: _currentPage,
        pageData: _pageData,
        selectedIndex: selectedIndex,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          _tabController.animateTo(index);
        },
      ),
    );
  }
}

class _SummaryPageContent extends StatefulWidget {
  final PageController pageController;
  final TabController tabController;
  final int currentPage;
  final List<Map<String, dynamic>> pageData;
  final int selectedIndex;
  final Function(int) onPageChanged;

  const _SummaryPageContent({
    required this.pageController,
    required this.tabController,
    required this.currentPage,
    required this.pageData,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  State<_SummaryPageContent> createState() => _SummaryPageContentState();
}

class _SummaryPageContentState extends State<_SummaryPageContent>
    with TickerProviderStateMixin {
  // Use late initialization
  late AnimationController _tabAnimationController;

  @override
  void initState() {
    super.initState();

    // Initialize controller with proper vsync
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Start the animation
    _tabAnimationController.forward();

    // Fetch data when this widget initializes
    Future.microtask(() =>
        Provider.of<ReportProvider>(context, listen: false).fetchReportData());
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current page color
    final Color activeColor =
        widget.pageData[widget.currentPage]["color"] as Color;

    return Scaffold(
      // Enhanced app bar with gradient and dynamic title
      appBar: AppBar(
        title: Consumer<ReportProvider>(
          builder: (context, provider, _) => Text(
            provider.sessionName, // Use dynamic session name from provider
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 0.3,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor,
                Color.lerp(activeColor, Colors.black, 0.2) ??
                    activeColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog(context, activeColor);
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          if (reportProvider.loading) {
            return _buildLoadingState();
          } else if (reportProvider.errorMessage.isNotEmpty) {
            return _buildErrorState(reportProvider);
          }

          return _buildMainContent(activeColor);
        },
      ),
      bottomNavigationBar: NavBar(selectedIndex: widget.selectedIndex),
    );
  }

  Widget _buildMainContent(Color activeColor) {
    return Column(
      children: [
        // Modernized tab navigation with improved separation and shadows
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Container(
                height: 52,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.pageData.length,
                    (index) => _buildTabButton(index, activeColor),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Page content with safe area to prevent overflow
        Expanded(
          child: PageView(
            controller: widget.pageController,
            onPageChanged: (index) {
              if (_tabAnimationController.isAnimating) {
                _tabAnimationController.stop();
              }
              _tabAnimationController.reset();
              widget.onPageChanged(index);
              _tabAnimationController.forward();
            },
            physics: BouncingScrollPhysics(),
            children: [
              ContextSummary(color: widget.pageData[0]["color"] as Color),
              GrammarSummary(color: widget.pageData[1]["color"] as Color),
              BodyLanguageSummary(color: widget.pageData[2]["color"] as Color),
              VoiceAnalysisSummary(color: widget.pageData[3]["color"] as Color),
            ],
          ),
        ),
      ],
    );
  }

  // Dynamic tab button based on text content
  Widget _buildTabButton(int index, Color activeColor) {
    final bool isActive = index == widget.currentPage;
    final Color tabColor = widget.pageData[index]["color"] as Color;
    final IconData tabIcon = widget.pageData[index]["icon"] as IconData;
    final String tabTitle = widget.pageData[index]["title"] as String;

    // Calculate dynamic width based on text length
    final double textWidth = tabTitle.length * 8.0; // Space per character
    final double minInactiveWidth = 50.0; // Minimum width for inactive tabs

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            // Use fast animation for direct tab switching
            widget.pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          width: isActive
              ? (textWidth + 60)
              : minInactiveWidth, // Dynamic width based on content
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? tabColor : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: tabColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive
                ? _buildActiveTabContent(tabIcon, tabTitle)
                : _buildInactiveTabContent(tabIcon, tabColor),
          ),
        ),
      ),
    );
  }

  // Animated active tab content
  Widget _buildActiveTabContent(IconData icon, String title) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            Transform.scale(
              scale: 0.8 + (value * 0.2), // Grow from 80% to 100%
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            // Animated text appearance
            ClipRect(
              child: Align(
                widthFactor: value,
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6 * value),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow
                          .visible, // Allow text to be fully visible
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Simplified widget for inactive tab with just the icon
  Widget _buildInactiveTabContent(IconData icon, Color color) {
    return Icon(
      icon,
      color: color,
      size: 20,
    );
  }

  void _showInfoDialog(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: themeColor),
              SizedBox(width: 10),
              Text(
                'About Analysis',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(
                'Context',
                'Analyzes the relevance and coherence of your presentation content.',
                Icons.subject,
                widget.pageData[0]["color"] as Color,
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                'Grammar',
                'Checks for grammatical errors and language quality.',
                Icons.spellcheck,
                widget.pageData[1]["color"] as Color,
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                'Body Language',
                'Assesses posture, gestures, and non-verbal communication.',
                Icons.accessibility_new,
                widget.pageData[2]["color"] as Color,
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                'Voice',
                'Evaluates your pace, tone, and vocal delivery.',
                Icons.mic,
                widget.pageData[3]["color"] as Color,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
      String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clean, modern circular progress indicator
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7400B8)),
                ),
              ),
            ),

            SizedBox(height: 32),

            // Simple, clean title
            Text(
              "Preparing Your Analysis",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                letterSpacing: 0.3,
              ),
            ),

            SizedBox(height: 12),

            // Subtitle with subtle color
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "We're analyzing your presentation to provide personalized insights",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ReportProvider reportProvider) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with subtle shadow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[700],
              ),
            ),

            SizedBox(height: 24),

            // Simple error title
            Text(
              "Unable to Load Data",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),

            SizedBox(height: 12),

            // Modern retry button
            ElevatedButton(
              onPressed: () {
                reportProvider.fetchReportData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400B8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}

// Base class for all summary screens with common functionality
abstract class BaseSummary extends StatelessWidget {
  final Color color;

  const BaseSummary({super.key, required this.color});

  // Methods to be implemented by subclasses
  String get title;
  IconData get icon;
  Widget buildContent(BuildContext context, ReportProvider provider);
  double? getScore(ReportProvider provider);
  List<Weakness>? getWeaknesses(ReportProvider provider);

  // Helper methods for score display
  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green.shade600;
    if (score >= 6) return Colors.blue.shade600;
    if (score >= 4) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 8) return Icons.verified;
    if (score >= 6) return Icons.thumb_up;
    if (score >= 4) return Icons.trending_up;
    return Icons.priority_high;
  }

  String _getScoreTitle(double score) {
    if (score >= 8) {
      return "Outstanding Performance";
    } else if (score >= 6) {
      return "Good Progress";
    } else if (score >= 4) {
      return "Room for Improvement";
    } else {
      return "Needs Attention";
    }
  }

  String _getDetailedScoreMessage(double score) {
    if (score >= 8) {
      return "You've demonstrated excellent skills in this area. Your presentation shows mastery and confidence.";
    } else if (score >= 6) {
      return "You're doing well with good foundational skills. Some refinement will take you to the next level.";
    } else if (score >= 4) {
      return "You show potential but need more practice. Focus on the improvement areas highlighted below.";
    } else {
      return "This area requires significant work. Follow the suggestions to build stronger skills.";
    }
  }

  String _getScoreMessage(double score) {
    if (score >= 8) {
      return "Excellent! You've mastered this aspect.";
    } else if (score >= 6) {
      return "Good performance with room for improvement.";
    } else if (score >= 4) {
      return "You're on the right track, but needs work.";
    } else {
      return "This area needs significant improvement.";
    }
  }

  List<Map<String, dynamic>> _getPerformanceInsights(double score) {
    List<Map<String, dynamic>> insights = [];

    if (score >= 8) {
      insights.add({
        'type': 'strength',
        'icon': Icons.check_circle_outline,
        'color': Colors.green.shade600,
        'text': 'Excellent command of this skill area.',
      });
      insights.add({
        'type': 'strength',
        'icon': Icons.star_border,
        'color': Colors.blue.shade600,
        'text':
            'Your performance in this area enhances your overall presentation.',
      });
    } else if (score >= 6) {
      insights.add({
        'type': 'strength',
        'icon': Icons.thumb_up_outlined,
        'color': Colors.blue.shade600,
        'text': 'Good fundamentals with consistent application.',
      });
      insights.add({
        'type': 'improvement',
        'icon': Icons.trending_up,
        'color': Colors.amber.shade700,
        'text':
            'Minor refinements will significantly enhance your effectiveness.',
      });
    } else if (score >= 4) {
      insights.add({
        'type': 'strength',
        'icon': Icons.check,
        'color': Colors.blue.shade600,
        'text': 'Basic skills are present but need development.',
      });
      insights.add({
        'type': 'improvement',
        'icon': Icons.build_outlined,
        'color': Colors.orange.shade700,
        'text': 'Regular practice will help build consistency in this area.',
      });
    } else {
      insights.add({
        'type': 'improvement',
        'icon': Icons.priority_high,
        'color': Colors.red.shade600,
        'text': 'This is a critical area requiring immediate attention.',
      });
      insights.add({
        'type': 'improvement',
        'icon': Icons.school_outlined,
        'color': Colors.orange.shade700,
        'text': 'Consider seeking additional training or resources.',
      });
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Container(
          color: Colors.grey.shade50,
          // Fix overflow issues - ensure proper constraints
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _buildScoreCard(context, provider),
                  ),
                ),
                if (_hasWeaknesses(provider)) ...[
                  SliverPadding(
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader(),
                    ),
                  ),
                  _buildWeaknessCards(context, provider),
                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ] else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          300, // Ensure adequate space
                      child: _buildNoWeaknessState(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasWeaknesses(ReportProvider provider) {
    final weaknesses = getWeaknesses(provider);
    return weaknesses != null && weaknesses.isNotEmpty;
  }

  Widget _buildScoreCard(BuildContext context, ReportProvider provider) {
    final score = getScore(provider) ?? 0;
    final scoreColor = _getScoreColor(score);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Simplified header with reduced prominence
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    Color.lerp(color, Colors.white, 0.3) ??
                        color.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Main content with cleaner layout
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Score level indicator centered above everything
                  Center(child: _buildScoreLevelLabel(score, scoreColor)),
                  SizedBox(height: 24),

                  // Graph centered
                  Center(
                    child: Container(
                      height: 160,
                      width: 160,
                      child: GraphDisplay(
                        score: score / 10,
                        color: color,
                      ),
                    ),
                  ),

                  // Simple score message - no border or header
                  Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      _getScoreTitle(score),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),

                  // Message text
                  Text(
                    _getDetailedScoreMessage(score),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Performance insights section
                  _buildPerformanceInsights(score),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Less prominent score level label
  Widget _buildScoreLevelLabel(double score, Color scoreColor) {
    String levelText;
    if (score >= 8) {
      levelText = "EXCELLENT";
    } else if (score >= 6) {
      levelText = "GOOD";
    } else if (score >= 4) {
      levelText = "FAIR";
    } else {
      levelText = "NEEDS WORK";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getScoreIcon(score), color: scoreColor, size: 14),
          SizedBox(width: 4),
          Text(
            levelText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: scoreColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Simplified score message for side-by-side layout
  Widget _buildEnhancedScoreMessage(double score, Color scoreColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with reduced padding
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              _getScoreTitle(score),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),

          // Concise message
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              _getDetailedScoreMessage(score),
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // More compact performance insights
  Widget _buildPerformanceInsights(double score) {
    List<Map<String, dynamic>> insights = _getPerformanceInsights(score);

    // Separate strengths and areas for improvement
    final strengths = insights
        .where((i) =>
            i['type'] == 'strength' ||
            i['color'] == Colors.green.shade600 ||
            i['color'] == Colors.blue.shade600)
        .toList();

    final improvements = insights
        .where((i) =>
            i['type'] == 'improvement' ||
            i['color'] == Colors.amber.shade700 ||
            i['color'] == Colors.orange.shade700 ||
            i['color'] == Colors.red.shade600)
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simplified header
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.insights, color: color, size: 16),
                SizedBox(width: 8),
                Text(
                  'Key Insights',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // Strengths section with more compact layout
          if (strengths.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'STRENGTHS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...strengths.map((insight) => _buildInsightItemEnhanced(insight)),
          ],

          // Areas for improvement section
          if (improvements.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'AREAS FOR IMPROVEMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...improvements
                .map((insight) => _buildInsightItemEnhanced(insight)),
          ],

          SizedBox(height: 8),
        ],
      ),
    );
  }

  // More compact insight item
  Widget _buildInsightItemEnhanced(Map<String, dynamic> insight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight['icon'],
            color: insight['color'],
            size: 14,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              insight['text'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          // Larger, more prominent icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, Colors.white, 0.3) ??
                      color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Focus Areas",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Targeted improvements for better performance",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessCard(BuildContext context, Weakness weakness) {
    final Color cardColor = color.withOpacity(0.03);
    final bool hasExamples =
        weakness.examples != null && weakness.examples!.isNotEmpty;
    final bool hasSuggestions =
        weakness.suggestions != null && weakness.suggestions!.isNotEmpty;

    // Function to format suggestions for clipboard
    String getSuggestionsText() {
      if (!hasSuggestions && !hasExamples) return "No suggestions available";

      final StringBuffer buffer = StringBuffer();
      buffer
          .writeln("IMPROVEMENT AREA: ${weakness.topic ?? 'Unknown Issue'}\n");

      if (hasSuggestions) {
        buffer.writeln("SUGGESTIONS:");
        for (int i = 0; i < weakness.suggestions!.length; i++) {
          buffer.writeln("${i + 1}. ${weakness.suggestions![i]}");
        }
      }

      if (hasExamples) {
        if (hasSuggestions)
          buffer.writeln("\nEXAMPLES:");
        else
          buffer.writeln("EXAMPLES:");
        for (int i = 0; i < weakness.examples!.length; i++) {
          buffer.writeln("${i + 1}. ${weakness.examples![i]}");
        }
      }

      return buffer.toString();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(primary: color),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            expandedAlignment: Alignment.topLeft,
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getWeaknessIcon(weakness.topic ?? ""),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              weakness.topic ?? 'Unknown Issue',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Tap to view ${hasExamples && hasSuggestions ? 'examples and suggestions' : hasExamples ? 'examples' : 'suggestions'}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            trailing: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: color,
                size: 24,
              ),
            ),
            children: [
              // Top divider with gradient
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.grey.shade200,
                      color.withOpacity(0.3),
                      Colors.grey.shade200,
                    ],
                  ),
                ),
              ),

              // Card content
              Container(
                width: double.infinity,
                color: cardColor,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weakness.examples != null &&
                        weakness.examples!.isNotEmpty) ...[
                      _buildWeaknessSection(
                        "Examples",
                        weakness.examples!,
                        Icons.format_quote_rounded,
                        color,
                      ),
                      SizedBox(height: 24),
                    ],
                    if (weakness.suggestions != null &&
                        weakness.suggestions!.isNotEmpty) ...[
                      _buildWeaknessSection(
                        "Suggestions",
                        weakness.suggestions!,
                        Icons.lightbulb_outline,
                        Colors.amber.shade700,
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom action bar with subtle gradient
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title with improved styling
                    Text(
                      "Practice this skill",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: getSuggestionsText()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text('Copied to clipboard'),
                                    ],
                                  ),
                                  backgroundColor: color,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: color.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 16, color: color),
                                  SizedBox(width: 6),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),

                        // Practice Button with improved styling
                        Material(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text('Added to your practice tasks'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_task,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Practice',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWeaknessIcon(String topic) {
    // Convert to lowercase and remove spaces for comparison
    final String normalizedTopic = topic.toLowerCase().replaceAll(' ', '');

    if (normalizedTopic.contains('grammar') ||
        normalizedTopic.contains('spell') ||
        normalizedTopic.contains('sentence')) {
      return Icons.spellcheck;
    } else if (normalizedTopic.contains('pace') ||
        normalizedTopic.contains('speed') ||
        normalizedTopic.contains('tone')) {
      return Icons.speed;
    } else if (normalizedTopic.contains('posture') ||
        normalizedTopic.contains('stance') ||
        normalizedTopic.contains('body')) {
      return Icons.accessibility_new;
    } else if (normalizedTopic.contains('volume') ||
        normalizedTopic.contains('loud') ||
        normalizedTopic.contains('quiet')) {
      return Icons.volume_up;
    } else if (normalizedTopic.contains('eye') ||
        normalizedTopic.contains('contact') ||
        normalizedTopic.contains('gaze')) {
      return Icons.visibility;
    } else if (normalizedTopic.contains('structure') ||
        normalizedTopic.contains('organization') ||
        normalizedTopic.contains('flow')) {
      return Icons.view_stream;
    } else if (normalizedTopic.contains('visual') ||
        normalizedTopic.contains('slide')) {
      return Icons.insert_photo;
    } else if (normalizedTopic.contains('transition')) {
      return Icons.compare_arrows;
    } else if (normalizedTopic.contains('gesture') ||
        normalizedTopic.contains('hand')) {
      return Icons.back_hand;
    }

    // Default icon if no match
    return Icons.priority_high;
  }

  Widget _buildWeaknessSection(
      String title, List<String> items, IconData itemIcon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with pill-shaped background
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                itemIcon,
                color: iconColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Items with cleaner layout
        ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numbered badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iconColor.withOpacity(0.8),
                        iconColor.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 14),

                // Item text with improved card styling
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      items[index],
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF3A3A3A),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoWeaknessState() {
    return Center(
      child: SingleChildScrollView(
        // Add SingleChildScrollView to handle overflow
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade600,
                ),
              ),
              SizedBox(height: 32),
              Text(
                "Great Job!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
              SizedBox(height: 12),
              Text(
                "No areas for improvement were found.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Keep up the excellent work!",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverPadding _buildWeaknessCards(
      BuildContext context, ReportProvider provider) {
    final weaknesses = getWeaknesses(provider) ?? [];

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final weakness = weaknesses[index];
            return _buildWeaknessCard(context, weakness);
          },
          childCount: weaknesses.length,
        ),
      ),
    );
  }
}

// Individual category implementations
class ContextSummary extends BaseSummary {
  const ContextSummary({super.key, required Color color}) : super(color: color);

  @override
  String get title => 'Context Analysis';

  @override
  IconData get icon => Icons.subject;

  @override
  double? getScore(ReportProvider provider) => provider.report.context.score;

  @override
  List<Weakness>? getWeaknesses(ReportProvider provider) =>
      provider.report.context.weaknesses;

  @override
  Widget buildContent(BuildContext context, ReportProvider provider) {
    return Container();
  }
}

class GrammarSummary extends BaseSummary {
  const GrammarSummary({super.key, required Color color}) : super(color: color);

  @override
  String get title => 'Grammar Analysis';

  @override
  IconData get icon => Icons.spellcheck;

  @override
  double? getScore(ReportProvider provider) => provider.report.grammar.score;

  @override
  List<Weakness>? getWeaknesses(ReportProvider provider) =>
      provider.report.grammar.weaknesses;

  @override
  Widget buildContent(BuildContext context, ReportProvider provider) {
    return Container();
  }
}

class BodyLanguageSummary extends BaseSummary {
  const BodyLanguageSummary({super.key, required Color color})
      : super(color: color);

  @override
  String get title => 'Body Language';

  @override
  IconData get icon => Icons.accessibility_new;

  @override
  double? getScore(ReportProvider provider) =>
      provider.report.bodyLanguage.score;

  @override
  List<Weakness>? getWeaknesses(ReportProvider provider) =>
      provider.report.bodyLanguage.weaknesses;

  @override
  Widget buildContent(BuildContext context, ReportProvider provider) {
    return Container();
  }
}

class VoiceAnalysisSummary extends BaseSummary {
  const VoiceAnalysisSummary({super.key, required Color color})
      : super(color: color);

  @override
  String get title => 'Voice Analysis';

  @override
  IconData get icon => Icons.mic;

  @override
  double? getScore(ReportProvider provider) => provider.report.voice.score;

  @override
  List<Weakness>? getWeaknesses(ReportProvider provider) =>
      provider.report.voice.weaknesses;

  @override
  Widget buildContent(BuildContext context, ReportProvider provider) {
    return Container();
  }
}
