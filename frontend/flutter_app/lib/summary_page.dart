import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _showTasks = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 50),
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: 0.9,
                color: Color(0xFF4EA7DE),
                strokeWidth: 10.0,
              ),
            ),
          ),
          SizedBox(height: 50),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton(
                  text: "Tasks",
                  isActive: _showTasks,
                  onPressed: () {
                    setState(() {
                      _showTasks = true;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildToggleButton(
                  text: "Resources",
                  isActive: !_showTasks,
                  onPressed: () {
                    setState(() {
                      _showTasks = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _showTasks ? TasksTab() : ResourcesTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Color(0xFF7400B8) : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ExpandableTile(
            title: "Appeared Uneasy",
            subtitle:
                "It looks like you might have felt a bit nervous during practice. That's okay! Just take things one step at a time, and remember to breathe. You've got this!",
          ),
          const SizedBox(height: 10),
          ExpandableTile(
            title: "Lack of Eye Contact",
            subtitle:
                "Don't be afraid to look your audience or the camera in the eye. It shows confidence and helps you connect with them on a deeper level.",
          ),
          const SizedBox(height: 10),
          ExpandableTile(
            title: "Overuse of Fillers",
            subtitle: "Engage in impromptu speaking exercises.",
          ),
        ],
      ),
    );
  }
}

class ResourcesTab extends StatelessWidget {
  ResourcesTab({super.key});

  // Sample data (could be fetched dynamically from an API)
  final List<Map<String, String>> videos = [
    {
      'title': '4 Essential body language tips froma  world champion public speaker',
      'subtitle': 'Business Insider',
      'thumbnail': 'https://img.youtube.com/vi/ZK3jSXYBNak/0.jpg',
      'url': 'https://www.youtube.com/watch?v=ZK3jSXYBNak'
    },
    {
      'title': 'Body Language for presenatations',
      'subtitle': 'Communication Coach Alexander Lyon',
      'thumbnail': 'https://img.youtube.com/vi/TmbQFWBvTtY/0.jpg',
      'url': 'https://www.youtube.com/watch?v=TmbQFWBvTtY'
    },

  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Padding(
            padding:
                const EdgeInsets.only(bottom: 20), // Add space between cards
            child: _buildRoundedTile(
              title: video['title']!,
              subtitle: video['subtitle']!,
              thumbnail: video['thumbnail']!,
              url: video['url']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundedTile({
    required String title,
    required String subtitle,
    required String thumbnail,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // Launch the video URL in a browser or WebView
          _launchURL(url);
        },
        leading: Image.network(
          thumbnail,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Display a placeholder icon in case of error
            return Icon(Icons.error, color: Colors.red);
          },
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Function to launch the video URL
  void _launchURL(String url) {
    launch(url);
    print("Launching URL: $url"); // Placeholder for URL launch
  }
}

class ExpandableTile extends StatefulWidget {
  final String title;
  final String subtitle;

  const ExpandableTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  _ExpandableTileState createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.remove : Icons.add,
                color: Colors.purple,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.subtitle,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
