import 'package:flutter/material.dart';

class AccountSetupGreeting extends StatelessWidget{
  const AccountSetupGreeting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x96B843FE),
      body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(padding: const EdgeInsets.all(2.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text('Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40.0),
              Text("Hello Gajitha",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              Spacer(),
              SizedBox(height: 16.0),
              Image.asset(
                'images/OnboardGreet_AccountSetupTitle.png',
                height: 400,
                width: 400,
              ),
              Spacer(),
              SizedBox(height: 20.0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text("Ready to take your presentation skills to the next level?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  child: Text("Get Started",
                    style: TextStyle(
                      color: Color(0xDB7400B8),
                      fontSize: 17,
                      fontFamily: 'Roboto',
                    ),
                  ),
                )
              )
            ],
          )
      ),
    );
  }
}