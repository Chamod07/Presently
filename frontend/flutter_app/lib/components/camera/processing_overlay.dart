import 'dart:async';
import 'package:flutter/material.dart';

class ProcessingOverlay extends StatefulWidget {
  final VoidCallback? onProcessingComplete;
  final Future<bool> Function()? checkProcessingStatus;
  final int pollingInterval; // in seconds

  const ProcessingOverlay({
    Key? key,
    this.onProcessingComplete,
    this.checkProcessingStatus,
    this.pollingInterval = 5,
  }) : super(key: key);

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  Timer? _pollingTimer;
  double _progressValue = 0.0;
  late AnimationController _fadeController;
  bool _longWait = false;
  bool _apiProcessing = true;
  bool _apiError = false;
  int _pollAttempts = 0;
  static const int maxPollAttempts = 60; // 5 minutes with 5-second interval

  final List<String> _processingMessages = [
    "Analyzing your voice patterns...",
    "Evaluating your body language...",
    "Examining your presentation context...",
    "Checking grammar and vocabulary...",
    "Identifying key improvement areas...",
    "Crafting personalized feedback...",
    "Assigning practice challenges...",
    "Measuring presentation confidence...",
    "Calculating engagement metrics...",
    "Finalizing your performance report..."
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeController.forward();

    // Start the message rotation
    _startMessageRotation();

    // Start simulated progress
    _simulateProgress();

    // Start polling for processing status
    if (widget.checkProcessingStatus != null) {
      _startStatusPolling();
    }

    // Show long wait message after 20 seconds
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _apiProcessing) {
        setState(() {
          _longWait = true;
        });
      }
    });
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _processingMessages.length;
        });
      }
    });
  }

  void _simulateProgress() {
    const totalDuration = 30000; // 30 seconds expected time
    const updateInterval = 100; // Update every 100ms
    const progressIncrement = 1.0 / (totalDuration / updateInterval);

    Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      if (mounted) {
        setState(() {
          if (_apiProcessing) {
            // While API is processing, progress slowly up to 90%
            if (_progressValue < 0.9) {
              _progressValue += progressIncrement;
            }
          } else if (!_apiError) {
            // When API is done and successful, complete to 100%
            _progressValue = 1.0;
            timer.cancel();
          } else {
            // If there's an API error, stop at current position
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startStatusPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: widget.pollingInterval),
        (timer) async {
      _pollAttempts++;

      if (_pollAttempts > maxPollAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _apiProcessing = false;
            _apiError = true;
          });
        }
        return;
      }

      // Update progress bar for visual feedback - faster progress
      setState(() {
        // Progress up to 90% more quickly
        _progressValue = (_pollAttempts / 4.0).clamp(0.0, 0.9);
      });

      if (widget.checkProcessingStatus != null) {
        try {
          bool isComplete = await widget.checkProcessingStatus!();

          if (isComplete) {
            timer.cancel();

            // Check if there was an upload success value
            // We assume that if no uploadSuccess is present, there was an error
            bool uploadSuccess = _apiProcessing; // Default to current state

            setState(() {
              _apiProcessing = false;
              _progressValue = 1.0;

              // Only set error if we haven't manually detected an error
              if (!_apiError && !uploadSuccess) {
                _apiError = true;
              }
            });

            // Navigate away after a LONGER delay if successful (3 seconds instead of 800ms)
            // to allow user to see the completion message
            if (!_apiError) {
              Future.delayed(Duration(seconds: 3), () {
                if (mounted && widget.onProcessingComplete != null) {
                  widget.onProcessingComplete!();
                }
              });
            }
          }
        } catch (e) {
          print('Error checking processing status: $e');

          // Set error state if exception occurs
          timer.cancel();
          if (mounted) {
            setState(() {
              _apiProcessing = false;
              _apiError = true;
              _progressValue = 0.3; // Show partial progress
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pollingTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeController,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or branding element
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Main title
                  const Text(
                    "Creating Your Analysis",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "Our AI is analyzing your presentation",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 50),

                  // Processing animation with rotating message
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _processingMessages[_currentMessageIndex],
                              key: ValueKey<int>(_currentMessageIndex),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _apiProcessing
                                ? "Processing your video"
                                : _apiError
                                    ? "Processing error"
                                    : "Analysis complete",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            "${(_progressValue * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF7400B8)),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),

                  // Completion message
                  if (!_apiProcessing && !_apiError) ...[
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Analysis Complete!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Your presentation has been analyzed successfully. Redirecting to results...",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Long wait message
                  if (_longWait && _apiProcessing) ...[
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade300,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This is taking longer than expected. Please wait while we complete your analysis.",
                              style: TextStyle(
                                color: Colors.amber.shade100,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Error message
                  if (_apiError) ...[
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Error processing your video",
                                  style: TextStyle(
                                    color: Colors.red.shade100,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your video has been saved. You can continue to the summary page.",
                                  style: TextStyle(
                                    color: Colors.red.shade100,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onProcessingComplete != null) {
                          widget.onProcessingComplete!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Continue"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
