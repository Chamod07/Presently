import 'package:flutter/material.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/components/summary/graph_display.dart';
import 'package:flutter_app/providers/report_provider.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _pageTitles = [
    "Context Summary",
    "Grammar Summary",
    "Body Language",
    "Voice Analysis",
  ];

  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    // Get selectedIndex from route arguments
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int selectedIndex =
        args?['selectedIndex'] ?? 1; // Default to 1 (add/new tab)

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _pageTitles[_currentPage],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF7400B8),
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Improved tab indicators with container
          Container(
            margin:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_pageTitles.length, (index) {
                return _buildTabIndicator(index);
              }),
            ),
          ),
          // PageView with all report categories
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: const [
                ContextSummary(),
                GrammarSummary(),
                BodyLanguageSummary(),
                VoiceAnalysisSummary(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(selectedIndex: selectedIndex),
    );
  }

  // Method to refresh data
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await Provider.of<ReportProvider>(context, listen: false)
          .fetchReportData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh data')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildTabIndicator(int index) {
    final isActive = index == _currentPage;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF7400B8) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Color(0xFF7400B8).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            _pageTitles[index]
                .split(' ')[0], // Just show first word for compactness
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Base class for all summary screens with common functionality
abstract class BaseSummary extends StatelessWidget {
  const BaseSummary({super.key});

  // Methods to be implemented by subclasses
  String get title;
  Widget buildContent(BuildContext context, ReportProvider provider);
  double? getScore(ReportProvider provider);
  List<Weakness>? getWeaknesses(ReportProvider provider);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReportProvider()..fetchReportData(),
      child: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return _buildLoadingState();
          } else if (provider.errorMessage.isNotEmpty) {
            return _buildErrorState(context, provider.errorMessage);
          } else {
            return _buildContentState(context, provider);
          }
        },
      ),
    );
  }

  // Improved loading state with progress indicator
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Color(0xFF7400B8),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your summary...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Improved error state
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7400B8),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Provider.of<ReportProvider>(context, listen: false)
                  .fetchReportData();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Improved content state with better styling
  Widget _buildContentState(BuildContext context, ReportProvider provider) {
    return Column(
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7400B8),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: GraphDisplay(score: (getScore(provider) ?? 0) / 10),
        ),
        SizedBox(height: 12),
        Text(
          _getScoreDescription((getScore(provider) ?? 0) / 10),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: buildWeaknessList(context, provider),
        ),
      ],
    );
  }

  // Helper method to get description based on score
  String _getScoreDescription(double score) {
    if (score >= 0.8) {
      return "Excellent! You've mastered this area.";
    } else if (score >= 0.6) {
      return "Good job! With a little more practice, you'll excel.";
    } else if (score >= 0.4) {
      return "You're making progress. Keep practicing!";
    } else {
      return "This area needs improvement. Focus on the suggestions below.";
    }
  }

  // Improved weakness list with better card design
  Widget buildWeaknessList(BuildContext context, ReportProvider provider) {
    final weaknesses = getWeaknesses(provider);
    if (weaknesses == null || weaknesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'No weaknesses found!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Great job! Continue practicing to maintain your skills.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: weaknesses.length,
      itemBuilder: (context, index) {
        final weakness = weaknesses[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
              Icons.warning_amber_outlined,
              color: Color(0xFF7400B8),
            ),
            title: Text(
              weakness.topic ?? 'Unknown Issue',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weakness.examples != null &&
                        weakness.examples!.isNotEmpty) ...[
                      const Text(
                        'Examples:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF7400B8),
                        ),
                      ),
                      SizedBox(height: 8),
                      ...weakness.examples!
                          .map((example) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(example)),
                                  ],
                                ),
                              ))
                          .toList(),
                      SizedBox(height: 12),
                    ],
                    if (weakness.suggestions != null &&
                        weakness.suggestions!.isNotEmpty) ...[
                      const Text(
                        'Suggestions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF7400B8),
                        ),
                      ),
                      SizedBox(height: 8),
                      ...weakness.suggestions!
                          .map((suggestion) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(suggestion)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ContextSummary extends BaseSummary {
  const ContextSummary({super.key});

  @override
  String get title => 'Context Summary';

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
  const GrammarSummary({super.key});

  @override
  String get title => 'Grammar Summary';

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
  const BodyLanguageSummary({super.key});

  @override
  String get title => 'Body Language';

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
  const VoiceAnalysisSummary({super.key});

  @override
  String get title => 'Voice Analysis';

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
