import 'package:flutter/material.dart';

class GraphDisplay extends StatelessWidget {
  const GraphDisplay({super.key});
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 150,
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            createGraph(0.7, 'images/Body_Language_Summary.png'),
            createGraph(0.8, 'images/Audio_Summary.png'),
            createGraph(0.9, 'images/Emotion_Summary.png'),
          ]
        ),
      ),
    );
  }
  Widget createGraph(double score, String image){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 150.0),
      child: Align(
        alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: score,
              color: Color(0xFF4EA7DE),
              strokeWidth: 10.0,
            ),
          ),
          Image.asset(
            image,
            width: 50,
            height: 50,
          ),
        ],
      )
      ),
    );
  }
}