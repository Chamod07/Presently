import 'package:flutter/material.dart';

class AccountSetupTitle extends StatelessWidget{
  const AccountSetupTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x96B843FE),
      body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40.0),
              Text("Welcome to Presently",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              Spacer(),
              SizedBox(height: 16.0),
              Image.asset(
                'images/OnboardGreet_AccountSetupTitle.png',
                height: 500,
                width: 500,
              ),
              Spacer(),
              SizedBox(height: 20.0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text("Tell us about yourself and we will tailor Presently according to your personality",
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
                      Navigator.pushNamed(context, '/account_setup_1');
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