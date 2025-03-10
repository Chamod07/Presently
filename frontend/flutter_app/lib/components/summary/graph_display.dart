import 'package:flutter/material.dart';

class GraphDisplay extends StatelessWidget {
  final double? score;

  const GraphDisplay({super.key, this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: _buildGraph(),
    );
  }

  Widget _buildGraph() {
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
                value: score ?? 0.0, // Provide a default value
                color: Color(0xFF4EA7DE),
                strokeWidth: 10.0,
              ),
            ),
            // Placeholder for content-specific icon
            Icon(Icons.description, size: 50),
          ],
        ),
      ),
    );
  }
}