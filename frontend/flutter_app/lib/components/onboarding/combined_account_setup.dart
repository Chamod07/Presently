import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _goToNextPage() {
    if (_currentPage == 0) {
      _validateAndGoToNextFromWelcome();
    } else if (_currentPage == 1) {
      _validateAndGoToNextFromNameEntry();
    } else if (_currentPage == 2) {
      _validateAndCompleteSetup();
    }
  }

  void _validateAndGoToNextFromWelcome() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Update progress immediately
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Update progress immediately
      setState(() {
        _currentPage = 2;
      });
    }
  }

  // Validation function to check if string contains only letters and spaces
  bool _containsOnlyLetters(String text) {
    final RegExp letterOnlyRegex = RegExp(r'^[a-zA-Z\s]+$');
    return letterOnlyRegex.hasMatch(text);
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

        // Navigate to greeting page
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Animated progress indicator
            AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF7400B8).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
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
                  );
                }),
            const SizedBox(height: 10),
            // Page content
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
    );
  }

  // Updated progress dot with smooth transitions
  Widget _buildProgressDot(int dotIndex, double currentPosition) {
    // Calculate how active this dot is based on progress
    double activeFactor = 0.0;

    if (dotIndex <= currentPosition.floor()) {
      activeFactor = 1.0; // Fully active for passed dots
    } else if (dotIndex == currentPosition.ceil()) {
      activeFactor = currentPosition -
          currentPosition.floor(); // Partially active for current dot
    }

    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          Colors.grey.withOpacity(0.3),
          Color(0xFF7400B8),
          activeFactor,
        ),
        border: Border.all(
          color: Color(0xFF7400B8).withOpacity(0.8),
          width: 1,
        ),
      ),
    );
  }

  // Updated progress line with smooth transitions
  Widget _buildProgressLine(int lineIndex, double currentPosition) {
    // Calculate how active this line is based on progress
    double activeFactor = 0.0;

    if (lineIndex < currentPosition.floor()) {
      activeFactor = 1.0; // Fully active for passed lines
    } else if (lineIndex == currentPosition.floor()) {
      activeFactor = currentPosition -
          currentPosition.floor(); // Partially active for current line
    }

    return Container(
      width: 25,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Color.lerp(
          Colors.grey.withOpacity(0.3),
          Color(0xFF7400B8),
          activeFactor,
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // PAGE 1: Welcome
  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome to Presently",
                    style: TextStyle(
                      color: Color(0xFF7400B8),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const Spacer(),
                  Hero(
                    tag: 'onboarding_image',
                    child: Image.asset(
                      'images/OnboardGreet_AccountSetupTitle.png',
                      height: constraints.maxWidth > constraints.maxHeight
                          ? constraints.maxHeight * 0.4
                          : constraints.maxWidth * 0.7,
                      width: constraints.maxWidth > constraints.maxHeight
                          ? constraints.maxHeight * 0.4
                          : constraints.maxWidth * 0.7,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 20.0),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Tell us about yourself and we'll create your personalized path to confident, compelling presentations.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7400B8),
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 32.0,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7400B8),
                        minimumSize:
                            Size(MediaQuery.of(context).size.width * 0.9, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _validateAndGoToNextFromWelcome,
                      child: const Text(
                        "Get Started",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // PAGE 2: Name Entry
  Widget _buildNameEntryPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'onboarding_image',
                child: Image.asset('images/SignIn_SignUp-removebg-preview.png',
                    height: 240, width: 240),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "What shall we call you?",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7400B8),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
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
                    color: _firstNameError ? Colors.red : Color(0x26000000),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x26000000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7400B8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                errorText: _errorMessage,
                prefixIcon: Icon(Icons.person, color: Color(0xFF7400B8)),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextField(
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
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x26000000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7400B8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon:
                    Icon(Icons.person_outline, color: Color(0xFF7400B8)),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _validateAndGoToNextFromNameEntry,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                backgroundColor: Color(0xFF7400B8),
                disabledBackgroundColor: Color(0xFF7400B8).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Continue",
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // PAGE 3: Role Selection
  Widget _buildRoleSelectionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'onboarding_image',
                child: Image.asset('images/SignIn_SignUp-removebg-preview.png',
                    height: 200, width: 200),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tell Us More About You!",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7400B8),
              ),
            ),
            const SizedBox(height: 30),
            DropdownButtonFormField(
              dropdownColor: Colors.white,
              isExpanded: true,
              icon:
                  Icon(Icons.arrow_drop_down_circle, color: Color(0xFF7400B8)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x26000000)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7400B8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.work_outline, color: Color(0xFF7400B8)),
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

            // Conditionally show text field for "Other" option
            if (selectedRole == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
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
                      borderSide: BorderSide(color: Color(0x26000000)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0x26000000)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7400B8)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: _otherRoleError,
                    prefixIcon:
                        Icon(Icons.edit_outlined, color: Color(0xFF7400B8)),
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
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _validateAndCompleteSetup,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                backgroundColor: Color(0xFF7400B8),
                disabledBackgroundColor: Color(0xFF7400B8).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "Complete Setup",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
