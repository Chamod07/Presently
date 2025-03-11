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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_pageTitles[_currentPage]),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab indicators
          Padding(
            padding: const EdgeInsets.all(8.0),
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
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }

  Widget _buildTabIndicator(int index) {
    final isActive = index == _currentPage;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF7400B8) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _pageTitles[index]
              .split(' ')[0], // Just show first word for compactness
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
            return Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text(provider.errorMessage));
          } else {
            return Column(
              children: [
                SizedBox(height: 20),
                Text(title,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Center(
                  child: GraphDisplay(score: (getScore(provider) ?? 0) / 10),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: buildWeaknessList(context, provider),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildWeaknessList(BuildContext context, ReportProvider provider) {
    final weaknesses = getWeaknesses(provider);
    if (weaknesses == null || weaknesses.isEmpty) {
      return Center(child: Text('No weaknesses found.'));
    }

    return ListView.builder(
      itemCount: weaknesses.length,
      itemBuilder: (context, index) {
        final weakness = weaknesses[index];
        return Card(
          child: ExpansionTile(
            title: Text(weakness.topic ?? 'Unknown Issue'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Examples:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    if (weakness.examples != null)
                      for (String example in weakness.examples!)
                        Text('- $example'),
                    const SizedBox(height: 8),
                    const Text('Suggestions:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    if (weakness.suggestions != null)
                      for (String suggestion in weakness.suggestions!)
                        Text('- $suggestion'),
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
    // Additional custom UI for context summary if needed
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
    // Additional custom UI for grammar summary if needed
    return Container();
  }
}

class BodyLanguageSummary extends BaseSummary {
  const BodyLanguageSummary({super.key});
  
  @override
  String get title => 'Body Language';
  
  @override
  double? getScore(ReportProvider provider) => provider.report.bodyLanguage.score;
  
  @override
  List<Weakness>? getWeaknesses(ReportProvider provider) => provider.report.bodyLanguage.weaknesses;
  
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
  List<Weakness>? getWeaknesses(ReportProvider provider) => provider.report.voice.weaknesses;
  
  @override
  Widget buildContent(BuildContext context, ReportProvider provider) {
    return Container();
  }
}
