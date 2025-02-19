import 'package:flutter/material.dart';

class GraphDisplay extends StatefulWidget {
  const GraphDisplay({super.key});

  @override
  State<GraphDisplay> createState() => _GraphDisplayState();
}

class _GraphDisplayState extends State<GraphDisplay> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView(
        children: <Widget> [
        Center( child:
            createGraph(0.7, 'images/Body_Language_Summary.png'),),
        Center( child:
            createGraph(0.8, 'images/Audio_Summary.png'),),
        Center( child:
            createGraph(0.9, 'images/Emotion_Summary.png'),),
        ],
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