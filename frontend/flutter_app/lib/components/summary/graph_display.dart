import 'package:flutter/material.dart';
import 'dart:math' as math;

class GraphDisplay extends StatefulWidget {
  final double? score;

  const GraphDisplay({super.key, this.score});

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
    return SizedBox(
      height: 150,
      child: _buildAnimatedGraph(),
    );
  }

  Widget _buildAnimatedGraph() {
    final normalizedScore = widget.score ?? 0.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Score indicator
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  color: _getScoreColor(normalizedScore),
                  backgroundColor: Colors.grey.shade200,
                  strokeWidth: 12.0,
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 10).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(normalizedScore),
                    ),
                  ),
                  Text(
                    'out of 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Category-specific icon
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
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
                  child: _getCategoryIcon(normalizedScore),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green.shade600;
    } else if (score >= 0.6) {
      return Colors.blue.shade600;
    } else if (score >= 0.4) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  Icon _getCategoryIcon(double score) {
    if (score >= 0.8) {
      return Icon(Icons.verified, color: Colors.green.shade600, size: 20);
    } else if (score >= 0.6) {
      return Icon(Icons.thumb_up, color: Colors.blue.shade600, size: 20);
    } else if (score >= 0.4) {
      return Icon(Icons.trending_up, color: Colors.orange.shade600, size: 20);
    } else {
      return Icon(Icons.priority_high, color: Colors.red.shade600, size: 20);
    }
  }
}
