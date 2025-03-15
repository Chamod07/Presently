import 'package:flutter/material.dart';

class GraphDisplay extends StatefulWidget {
  final double? score;
  final Color? color; // Category color (now only used as fallback)

  const GraphDisplay({super.key, this.score, this.color});

  @override
  State<GraphDisplay> createState() => _GraphDisplayState();
}

class _GraphDisplayState extends State<GraphDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.score ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      child: _buildAnimatedGraph(),
    );
  }

  Widget _buildAnimatedGraph() {
    final normalizedScore = widget.score ?? 0.0;
    // Always use score-based color instead of passed color
    final displayColor = _getScoreColor(normalizedScore);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: displayColor.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),

            // Score indicator
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: _animation.value,
                color: displayColor, // Score-based color
                backgroundColor: Colors.grey.shade100,
                strokeWidth: 14.0,
                strokeCap: StrokeCap.round,
              ),
            ),

            // Score text with color matching the score
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_animation.value * 10).toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: displayColor, // Score-based color
                  ),
                ),
                Text(
                  'out of 10',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            // Category-specific icon with inverted colors
            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _getCategoryIcon(normalizedScore, displayColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green.shade600; // Excellent
    } else if (score >= 0.6) {
      return Colors.blue.shade600; // Good
    } else if (score >= 0.4) {
      return Colors.orange.shade600; // Needs improvement
    } else {
      return Colors.red.shade600; // Poor
    }
  }

  Icon _getCategoryIcon(double score, Color iconColor) {
    if (score >= 0.8) {
      return Icon(Icons.verified, color: iconColor, size: 24);
    } else if (score >= 0.6) {
      return Icon(Icons.thumb_up, color: iconColor, size: 24);
    } else if (score >= 0.4) {
      return Icon(Icons.trending_up, color: iconColor, size: 24);
    } else {
      return Icon(Icons.priority_high, color: iconColor, size: 24);
    }
  }
}
