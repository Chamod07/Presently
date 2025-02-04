import 'package:flutter/material.dart';
import 'package:flutter_app/navbar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Hello Mariah,'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                'https://via.placeholder.com/150',
              ),
            ),
            onPressed: () {
              // Navigate to notifications screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello Mariah,',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Let\'s ace your next presentation',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/scenario_sel'); // Start session
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400B8),
                foregroundColor: Colors.white,
                // minimumSize: Size.fromHeight(20),
              ),
              child: Text('Start Session',
                style: TextStyle(fontSize: 17),
              ),
            ),
            SizedBox(height: 15.0),
            Expanded(
              child: ListView(
                children: [
                  _buildCard(
                    title: 'Machine Learning',
                    navigateTo: '/summary',
                  ),
                  SizedBox(height: 16.0),
                  _buildCard(
                    title: 'Psychology Traits',
                    navigateTo: '/summary',
                  ),
                  SizedBox(height: 16.0),
                  _buildCard(
                    title: 'Developmental Behavior',
                    navigateTo: '/summary',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar (selectedIndex: 0,),
    );
  }

  Widget _buildCard({
    required String title,
    required String navigateTo,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, navigateTo);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.bookmark_border,
              color: Colors.grey,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Presentation | University',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}