import 'package:flutter/material.dart';
import 'package:flutter_app/navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/sign_in.dart';//Added only for the sign out button

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

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
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => SignInPage()),
                    (route) => false,
                  );
                }
              }catch (error){
                if (context.mounted){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error signing out'),
                        backgroundColor: Colors.red,
                    ),
                  );
                }
              }
    }
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                ),
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

            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/scenario_sel');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400B8),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Start Session', style: TextStyle(fontSize: 17)),
                ),
                SizedBox(width: 16), // Space between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/task_group_page');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list, size: 20),
                        SizedBox(width: 8),
                        Text('Tasks', style: TextStyle(fontSize: 17)),
                      ],
                    ),
                  ),
                ),
              ],
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