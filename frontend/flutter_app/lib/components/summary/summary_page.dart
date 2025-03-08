import 'package:flutter/material.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/components/summary/graph_display.dart';
import 'package:flutter_app/providers/report_provider.dart';
import 'package:provider/provider.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        children: const [
          ContextSummary(),
          GrammarSummary(),
        ],
      ),
      bottomNavigationBar: const NavBar(selectedIndex: 0),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class ContextSummary extends StatelessWidget {
  const ContextSummary({super.key});
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
                SizedBox(height: 50),
                Center(
                  child: GraphDisplay(score: (provider.report.scoreContext ?? 0) / 10),
                ),
                SizedBox(height: 50),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.report.weaknesses?.length ?? 0,
                    itemBuilder: (context, index) {
                      final weakness = provider.report.weaknesses![index];
                      return Card(
                        child: ExpansionTile(
                          title: Text(weakness.topic ?? 'Unknown Weakness'),
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  if (weakness.examples != null)
                                    for (String example in weakness.examples!)
                                      Text('- $example'),
                                  const SizedBox(height: 8),
                                  const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class GrammarSummary extends StatelessWidget {
  const GrammarSummary({super.key});
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
                SizedBox(height: 50),
                Center(
                  child: GraphDisplay(score: (provider.report.scoreGrammar ?? 0) / 10),
                ),
                SizedBox(height: 50),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.report.grammarWeaknesses?.length ?? 0,
                    itemBuilder: (context, index) {
                      final weakness = provider.report.grammarWeaknesses![index];
                      return Card(
                        child: ExpansionTile(
                          title: Text(weakness.topic ?? 'Grammar Issue'),
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  if (weakness.examples != null)
                                    for (String example in weakness.examples!)
                                      Text('- $example'),
                                  const SizedBox(height: 8),
                                  const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class BodyLanguageSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Body Language Summary'));
  }
}