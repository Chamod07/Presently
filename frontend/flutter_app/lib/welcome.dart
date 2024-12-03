
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage ({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Center(
              child: Text("Presently" ,
                  style: TextStyle(
                      fontFamily: 'Cookie-Regular.ttf',
                      fontSize: 48,
                      color: Color(0xFF7300B8)
                  )
              )
            )
          ),
        Padding(padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(onPressed: () {Navigator.pushNamed(context, '/sign_in');},
            icon: Icon(Icons.arrow_forward),
            label: Text("Let's Get Started!",
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF7400B8),
              fontFamily: 'Roboto-Medium.ttf'
            ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: Color(0xFF7400B8)
                )
              )
            )
        )
          )
        ],)

      )
      );
  }
}
