import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math';

class CombinedAccountSetup extends StatefulWidget {
  const CombinedAccountSetup({Key? key}) : super(key: key);

  @override
  State<CombinedAccountSetup> createState() => _CombinedAccountSetupState();
}

class _CombinedAccountSetupState extends State<CombinedAccountSetup>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Add animation controller for smooth progress indicator transition
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? selectedRole;
  final _otherRoleController = TextEditingController();

  // Form validation
  bool _firstNameError = false;
  String? _errorMessage;
  String? _otherRoleError;

  final List<String> userStatus = [
    'Student',
    'Undergraduate',
    'Postgraduate',
    'Young Professional',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Create animation for progress
    _progressAnimation = Tween<double>(begin: 0, end: 2).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _firstNameController.addListener(() {
      if (_firstNameError && _firstNameController.text.trim().isNotEmpty) {
        setState(() {
          _firstNameError = false;
          _errorMessage = null;
        });
      }
    });

    // Listen to page changes and update animation
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    // Calculate progress based on page controller
    final double pageValue = _pageController.page ?? 0;
    _animationController.value =
        pageValue / 2; // Normalize to 0-1 range for the controller
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _animationController.dispose();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherRoleController.dispose();
    super.dispose();
  }

  void _validateAndGoToNextFromWelcome() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = 1;
    });
  }

  void _validateAndGoToNextFromNameEntry() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty;
      _errorMessage = _firstNameError ? 'First name is required' : null;
    });

    if (!_firstNameError) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = 2;
      });
    }
  }

  void _validateAndCompleteSetup() async {
    // Validate the custom role if "Other" is selected
    if (selectedRole == 'Other') {
      final customRole = _otherRoleController.text.trim();

      if (customRole.isEmpty) {
        setState(() {
          _otherRoleError = 'Please specify your role';
        });
        return;
      }

      if (!_containsOnlyLetters(customRole)) {
        setState(() {
          _otherRoleError = 'Only letters are allowed';
        });
        return;
      }

      // Use the custom role instead of "Other"
      selectedRole = customRole;
    }

    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a role before continuing.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    String? userId = args?['userId'];
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();

    if (userId != null) {
      try {
        // Update UserDetails table with both name and role in one call
        final response = await Supabase.instance.client
            .from('UserDetails')
            .update({
              'firstName': firstName,
              'lastName': lastName,
              'role': selectedRole,
            })
            .eq('userId', userId)
            .select();

        if (response.isEmpty) {
          throw Exception('Update failed, no matching user found.');
        }

        debugPrint('User details update successful: $response');

        // Navigate to greeting page with animation
        Navigator.pushNamed(
          context,
          '/account_setup_greeting',
          arguments: {
            'firstName': firstName,
            'lastName': lastName,
          },
        );
      } catch (e) {
        debugPrint('Error updating user details: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update details. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not found'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Validation function to check if string contains only letters and spaces
  bool _containsOnlyLetters(String text) {
    final RegExp letterOnlyRegex = RegExp(r'^[a-zA-Z\s]+$');
    return letterOnlyRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF1E6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Animated progress indicator with improved design
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF9D4EDD).withOpacity(0.2),
                                Color(0xFF7400B8).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF7400B8).withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildProgressDot(0, _progressAnimation.value),
                              _buildProgressLine(0, _progressAnimation.value),
                              _buildProgressDot(1, _progressAnimation.value),
                              _buildProgressLine(1, _progressAnimation.value),
                              _buildProgressDot(2, _progressAnimation.value),
                              _buildProgressLine(2, _progressAnimation.value),
                              _buildProgressDot(3, _progressAnimation.value),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 10),

              // Page content with animations
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(), // Disable swiping
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildNameEntryPage(),
                    _buildRoleSelectionPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced progress dot with pulse animation and better glow effect
  Widget _buildProgressDot(int dotIndex, double currentPosition) {
    // Calculate how active this dot is based on progress
    double activeFactor = 0.0;

    if (dotIndex <= currentPosition.floor()) {
      activeFactor = 1.0; // Fully active for passed dots
    } else if (dotIndex == currentPosition.ceil()) {
      activeFactor = currentPosition -
          currentPosition.floor(); // Partially active for current dot
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: Duration(milliseconds: activeFactor > 0.5 ? 900 : 0),
      curve: Curves.easeInOut,
      builder: (context, pulse, child) {
        return Transform.scale(
          scale: activeFactor > 0.5 ? pulse : 1.0,
          child: Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: activeFactor > 0.5
                    ? [
                        Color(0xFF9D4EDD),
                        Color(0xFF7400B8),
                      ]
                    : [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.3),
                      ],
              ),
              border: Border.all(
                color: Color(0xFF7400B8).withOpacity(0.8),
                width: 1,
              ),
              boxShadow: activeFactor > 0.5
                  ? [
                      BoxShadow(
                        color:
                            Color(0xFF7400B8).withOpacity(0.3 * activeFactor),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  // Updated progress line with gradient and animation
  Widget _buildProgressLine(int lineIndex, double currentPosition) {
    // Calculate how active this line is based on progress
    double activeFactor = 0.0;

    if (lineIndex < currentPosition.floor()) {
      activeFactor = 1.0; // Fully active for passed lines
    } else if (lineIndex == currentPosition.floor()) {
      activeFactor = currentPosition -
          currentPosition.floor(); // Partially active for current line
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 25,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activeFactor > 0
              ? [
                  Color(0xFF9D4EDD).withOpacity(activeFactor),
                  Color(0xFF7400B8).withOpacity(activeFactor),
                ]
              : [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // PAGE 1: Welcome with enhanced visuals and decorative elements
  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: AnimationLimiter(
            child: Container(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 0,
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 20),
                    // Decorative element
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF9D4EDD).withOpacity(0.5),
                            Color(0xFF7400B8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Enhanced title with gradient text
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFF9D4EDD), Color(0xFF7400B8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        "Welcome to Presently",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    // Replace Spacer with flexible SizedBox
                    SizedBox(height: constraints.maxHeight * 0.07),

                    // Animated hero image with decoration
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background decoration
                        Container(
                          width: constraints.maxWidth * 0.75,
                          height: constraints.maxWidth * 0.75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF9D4EDD).withOpacity(0.1),
                                Colors.white.withOpacity(0),
                              ],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                        // Image with animation
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.9, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Hero(
                            tag: 'onboarding_image',
                            child: Image.asset(
                              'images/OnboardGreet_AccountSetupTitle.png',
                              height:
                                  constraints.maxWidth > constraints.maxHeight
                                      ? constraints.maxHeight * 0.4
                                      : constraints.maxWidth * 0.7,
                              width:
                                  constraints.maxWidth > constraints.maxHeight
                                      ? constraints.maxHeight * 0.4
                                      : constraints.maxWidth * 0.7,
                            ),
                          ),
                        ),
                        // Floating decorative elements
                        ...List.generate(6, (index) {
                          return Positioned(
                            left: (index % 3 * 50.0) +
                                (constraints.maxWidth * 0.25),
                            top: (index ~/ 3 * 80.0) +
                                (constraints.maxWidth * 0.15),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration:
                                  Duration(milliseconds: 800 + (index * 200)),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Color(0xFF9D4EDD).withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),

                    // Replace Spacer with flexible SizedBox
                    SizedBox(height: constraints.maxHeight * 0.07),

                    const SizedBox(height: 20.0),

                    // Enhanced description with improved styling
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Stack(
                        children: [
                          // Main container
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Color(0xFF7400B8).withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              "Tell us about yourself and we'll create your personalized path to confident, compelling presentations.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7400B8),
                                fontSize: 15,
                                fontFamily: 'Roboto',
                                height: 1.5,
                              ),
                            ),
                          ),

                          // Decorative element on top
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF7400B8).withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF9D4EDD),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Replace Spacer with flexible SizedBox
                    SizedBox(height: constraints.maxHeight * 0.08),

                    // Get Started button with enhanced visuals
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 32.0,
                      ),
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF7400B8).withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF9D4EDD),
                                Color(0xFF7400B8),
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _validateAndGoToNextFromWelcome(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Get Started",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // PAGE 2: Name Entry with enhanced visuals
  Widget _buildNameEntryPage() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 0,
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: [
                const SizedBox(height: 20),

                // Animated hero image with enhanced background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background decorative elements
                    ...List.generate(3, (index) {
                      return Positioned(
                        left: [50.0, 150.0, 250.0][index],
                        top: [20.0, 80.0, 40.0][index],
                        child: Container(
                          width: [100.0, 80.0, 60.0][index],
                          height: [100.0, 80.0, 60.0][index],
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF9D4EDD).withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Hero image
                    Hero(
                      tag: 'onboarding_image',
                      child: Image.asset(
                        'images/SignIn_SignUp-removebg-preview.png',
                        height: 240,
                        width: 240,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Animated title with gradient
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF9D4EDD), Color(0xFF7400B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "What shall we call you?",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // First name field with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _firstNameError
                            ? Colors.red.withOpacity(0.2)
                            : Color(0xFF7400B8).withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: "First Name",
                      labelStyle: TextStyle(
                        fontFamily: "Roboto",
                        color: Color(0xFFBDBDBD),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _firstNameError ? Colors.red : Color(0x26000000),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _firstNameError ? Colors.red : Color(0x26000000),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              _firstNameError ? Colors.red : Color(0xFF7400B8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      errorText: _errorMessage,
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color(0xFF7400B8).withOpacity(0.8),
                      ),
                      hintText: "Enter your first name",
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),

                const SizedBox(height: 20),

                // Last name field with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF7400B8).withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: "Last Name",
                      labelStyle: TextStyle(
                        fontFamily: "Roboto",
                        color: Color(0xFFBDBDBD),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0x26000000)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0x26000000)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF7400B8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFF7400B8).withOpacity(0.8),
                      ),
                      hintText: "Enter your last name",
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),

                const SizedBox(height: 40),

                // Continue button with enhanced styling
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF7400B8).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9D4EDD),
                          Color(0xFF7400B8),
                        ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _validateAndGoToNextFromNameEntry,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            Size(MediaQuery.of(context).size.width * 0.9, 56),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PAGE 3: Role Selection with enhanced visuals
  Widget _buildRoleSelectionPage() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 0,
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: [
                const SizedBox(height: 20),

                // Hero image with decorative background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background decoration
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF9D4EDD).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Hero image
                    Hero(
                      tag: 'onboarding_image',
                      child: Image.asset(
                        'images/SignIn_SignUp-removebg-preview.png',
                        height: 200,
                        width: 200,
                      ),
                    ),
                    // Decorative elements
                    ...List.generate(5, (index) {
                      return Positioned(
                        left: 110 + 60 * cos(index * (3.14159 / 2.5)),
                        top: 110 + 60 * sin(index * (3.14159 / 2.5)),
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 600 + (index * 200)),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: [8.0, 6.0, 10.0, 7.0, 9.0][index],
                                height: [8.0, 6.0, 10.0, 7.0, 9.0][index],
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF9D4EDD).withOpacity(0.4),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // Title with animation and gradient
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF9D4EDD), Color(0xFF7400B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "Tell Us More About You!",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Dropdown with enhanced styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF7400B8).withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: DropdownButtonFormField(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down_circle,
                        color: Color(0xFF7400B8),
                      ),
                      decoration: InputDecoration(
                        labelText: "I describe myself as a...",
                        labelStyle: TextStyle(
                          fontFamily: "Roboto",
                          color: Color(0xFFBDBDBD),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0x26000000)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF7400B8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: Icon(
                          Icons.work_outline,
                          color: Color(0xFF7400B8).withOpacity(0.8),
                        ),
                      ),
                      items: userStatus.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
                          if (newValue != 'Other') {
                            _otherRoleError = null;
                          }
                        });
                      },
                      hint: Text('Select your role'),
                    ),
                  ),
                ),

                // Conditionally show text field for "Other" option with slide-in animation
                if (selectedRole == 'Other')
                  SlideAnimation(
                    verticalOffset: 20,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _otherRoleError != null
                                    ? Colors.red.withOpacity(0.2)
                                    : Color(0xFF7400B8).withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _otherRoleController,
                            decoration: InputDecoration(
                              labelText: "Please specify",
                              labelStyle: TextStyle(
                                fontFamily: "Roboto",
                                color: Color(0xFFBDBDBD),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0x26000000)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0x26000000)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF7400B8),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              errorText: _otherRoleError,
                              prefixIcon: Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF7400B8).withOpacity(0.8),
                              ),
                              hintText: "Enter your role",
                            ),
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              // Clear error when user starts typing
                              if (_otherRoleError != null) {
                                setState(() {
                                  _otherRoleError = null;
                                });
                              }
                            },
                            // Real-time validation while typing
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z\s]')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Complete setup button with enhanced styling
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF7400B8).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isLoading
                            ? [
                                Color(0xFF9D4EDD).withOpacity(0.7),
                                Color(0xFF7400B8).withOpacity(0.7),
                              ]
                            : [
                                Color(0xFF9D4EDD),
                                Color(0xFF7400B8),
                              ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndCompleteSetup,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            Size(MediaQuery.of(context).size.width * 0.9, 56),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Complete Setup",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
