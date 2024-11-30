import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello Mariah'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let’s ace your next presentation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/scenario_sel');
                //Navigate to Scenario selection page
              },
              child: Text("Start Session"),
            ),

            const SizedBox(height: 30),
            const Text(
              "Most Recent",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Replace with actual recording data
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.video_library, color: Colors.purple),
                    title: Text('Presentation ${index + 1}'),
                    subtitle: Text('Date: ${DateTime.now().toLocal()}'),
                    onTap: () {
                      // Navigate to summary page
                      Navigator.pushNamed(context, '/summary');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedItemColor: Colors.purple,
      ),
    );
  }
}