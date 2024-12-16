import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
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
            child: _showTasks ? const TasksTab() : const ResourcesTab(),
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
        backgroundColor: isActive ? Color(0xFF7400B8): Colors.grey[300],
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
  const ResourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildRoundedTile(
            title: "Body Language for Presentations",
            subtitle: "Communication Coach Alexander Lyon",
            icon: Icons.video_library,
          ),
          const SizedBox(height: 10),
          _buildRoundedTile(
            title: "Body Language Tips",
            subtitle: "Master the art of non-verbal communication.",
            icon: Icons.video_library,
          ),
          const SizedBox(height: 10),
          _buildRoundedTile(
            title: "Voice Modulation Practice",
            subtitle: "Enhance your vocal variety.",
            icon: Icons.video_library,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedTile({
    required String title,
    required String subtitle,
    IconData? icon,
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
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: icon != null ? Icon(icon) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
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