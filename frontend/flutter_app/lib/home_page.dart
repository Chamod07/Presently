import 'package:flutter/material.dart';
import 'package:flutter_app/navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/sign_in.dart';//Added only for the sign out button
import 'package:provider/provider.dart';
import 'session_provider.dart';

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
              // Navigate to notifications screen
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
      body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150',
                  ),
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
                    Navigator.pushNamed(context, '/scenario_sel'); // Start session
                  },
                  child: Text('Start Session'),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child:Consumer<SessionProvider>(
                builder: (context,sessionProvider, child){
                  return ListView.builder(
                    itemCount: sessionProvider.sessions.length,
                    itemBuilder: (context, index){
                      return _buildCard(
                        title: sessionProvider.sessions[index],
                        navigateTo: '/summary',
                      );
                    },
                  );
                }
              )
            ),
          ],
        ),
      ),
      ),
      bottomNavigationBar: const NavBar (selectedIndex: 0,),
    );
  }

  Widget _buildCard(
      {
    required String title,
    required String navigateTo,

      }
      )
  {
    return GestureDetector(
      onTap: () {
        // Navigate to the summary page
        Navigator.pushNamed(context, navigateTo);
      },
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}