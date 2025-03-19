import 'package:flutter/material.dart';
import '../../services/upload/upload_service.dart';

class UploadStatusOverlay extends StatefulWidget {
  final Widget child;

  const UploadStatusOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<UploadStatusOverlay> createState() => _UploadStatusOverlayState();
}

class _UploadStatusOverlayState extends State<UploadStatusOverlay> with SingleTickerProviderStateMixin {
  final UploadService _uploadService = UploadService();
  Map<String, dynamic>? _latestStatus;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  bool _visible = false;

  @override
  void initState() {
    super.initState();

    // Set up animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Listen to upload status updates
    _uploadService.statusStream.listen(_handleStatusUpdate);
  }

  void _handleStatusUpdate(Map<String, dynamic> status) {
    // Filter out some statuses if needed
    if (status['status'] == 'idle' && _visible) {
      // Hide after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _visible = false;
            _controller.reverse();
          });
        }
      });
      return;
    }

    // Show the overlay for active uploads
    if (!_visible && status['status'] != 'idle') {
      setState(() {
        _visible = true;
        _latestStatus = status;
        _controller.forward();
      });
    } else if (mounted) {
      setState(() {
        _latestStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible && _latestStatus != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIconForStatus(_latestStatus!['status']),
                            color: _getColorForStatus(_latestStatus!['status']),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _latestStatus!['message'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_latestStatus!['status'] == 'uploading' ||
                          _latestStatus!['status'] == 'processing')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: _latestStatus!['progress'],
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForStatus(_latestStatus!['status'])),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'queued':
        return Icons.queue;
      case 'uploading':
        return Icons.cloud_upload;
      case 'processing':
        return Icons.settings;
      case 'complete':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'retrying':
        return Icons.refresh;
      case 'waiting':
        return Icons.signal_wifi_off;
      default:
        return Icons.info;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'complete':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'retrying':
        return Colors.orange;
      case 'waiting':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}