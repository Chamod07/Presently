import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget{
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
        ),
      ),
      body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
            child: Column(
              children: [
            Text(
              'Steady Stare',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            ),
            Text(
              'Level Up',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontFamily: 'Roboto'),
            ),
            SizedBox(height: 5),
            Text(
              'SDGP Project Presentation',
              style: TextStyle(fontSize: 17, color: Colors.grey, fontFamily: 'Roboto'),
            ),
            SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text("2 Points",
                    style: TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                  child:Text("Duration: 30 sec",
                  style: TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                  ),
                  ),
                ],
              ),

            ]
            ),
            ),

            SizedBox(height: 20),
            Text("Description",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text("This task is to enhance your eye contact skills, which are crucial for effective communication and building rapport.",
            style: TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Roboto'),
            ),
            SizedBox(height: 20),
            Text("Instructions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            ),
            SizedBox(height: 5),
            Text("1. Take a few deep breaths to calm your nerves.",
            style: TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Roboto'),
            ),
            Text("2. Skim through your report to refresh your memory.",
            style: TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Roboto')
            ),
            Text("3. Good luck on your first challenge.",
            style: TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Roboto')
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400B8),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Center(
                child: Text(
                  "Start now!",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                )
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}