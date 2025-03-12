import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';

class ScenarioSelection extends StatefulWidget {
  const ScenarioSelection({super.key});

  @override
  _ScenarioSelectionScreenState createState() =>
      _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelection> {
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;
  String? _selectedAudience;
  String? _selectedTopic;

  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();

  // Map icons to presentation types
  final Map<String, IconData> _presentationIcons = {
    'business': Icons.business,
    'academic': Icons.school,
    'pub_speaking': Icons.record_voice_over,
    'interview': Icons.people,
    'casual': Icons.chat,
  };

  // Map icons to goals
  final Map<String, IconData> _goalIcons = {
    'Inform': Icons.info,
    'Persuade': Icons.psychology,
    'Entertain': Icons.theater_comedy,
    'Inspire': Icons.emoji_emotions,
  };

  // Map audience types to icons
  final Map<String, IconData> _audienceIcons = {
    'professionals': Icons.work,
    'students': Icons.school_outlined,
    'general_public': Icons.groups,
    'experts': Icons.psychology_outlined,
    'mixed': Icons.diversity_3,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Presentation Setup',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Color(0xFF7400B8)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF7400B8)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        backgroundColor: Colors.white, // White background instead of purple
        elevation: 0, // No shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7400B8).withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              onStepContinue: () {
                if (_currentStep < 4) {
                  setState(() {
                    _currentStep += 1;
                  });
                } else {
                  _submitForm();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7400B8),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(_currentStep < 4
                              ? 'Continue'
                              : 'Start Practicing'),
                        ),
                      ),
                      if (_currentStep > 0) SizedBox(width: 12),
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF7400B8),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Color(0xFF7400B8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Previous'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Presentation Type
                Step(
                  title: Text('Presentation Type',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('What kind of presentation are you preparing for?'),
                  content: _buildPresentationTypeSelector(),
                  isActive: _currentStep >= 0,
                  state: _selectedPresentationType != null
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // Step 2: Presentation Goal
                Step(
                  title: Text('Presentation Goal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('What do you want to achieve?'),
                  content: _buildPresentationGoalSelector(),
                  isActive: _currentStep >= 1,
                  state: _selectedPresentationGoal != null
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // Step 3: Target Audience
                Step(
                  title: Text('Target Audience',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Who are you presenting to?'),
                  content: _buildAudienceSelector(),
                  isActive: _currentStep >= 2,
                  state: _selectedAudience != null
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // Step 4: Presentation Topic
                Step(
                  title: Text('Presentation Topic',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('What will you be talking about?'),
                  content: _buildTopicInput(),
                  isActive: _currentStep >= 3,
                  state: _selectedTopic != null && _selectedTopic!.isNotEmpty
                      ? StepState.complete
                      : StepState.indexed,
                ),
                // Step 5: Session Name
                Step(
                  title: Text('Session Name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Name your practice session'),
                  content: _buildNameInput(),
                  isActive: _currentStep >= 4,
                  state: _selectedName != null && _selectedName!.isNotEmpty
                      ? StepState.complete
                      : StepState.indexed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresentationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The type of presentation affects speaking style, formality, and techniques you should use.',
          style:
              TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        ...['business', 'academic', 'pub_speaking', 'interview', 'casual']
            .map((type) {
          String title;
          String description;

          switch (type) {
            case 'business':
              title = 'Business Presentation';
              description = 'Sales pitches, reports, strategy meetings';
              break;
            case 'academic':
              title = 'Academic Presentation';
              description = 'Lectures, conferences, thesis defense';
              break;
            case 'pub_speaking':
              title = 'Public Speaking Event';
              description = 'Keynotes, community events, ceremonies';
              break;
            case 'interview':
              title = 'Interview or Job Talk';
              description = 'Job interviews, panel discussions';
              break;
            case 'casual':
              title = 'Casual Speech';
              description = 'Toasts, informal talks, celebrations';
              break;
            default:
              title = type;
              description = '';
          }

          return Card(
            elevation: _selectedPresentationType == type ? 4 : 1,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedPresentationType == type
                    ? Color(0xFF7400B8)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPresentationType = type;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _presentationIcons[type] ?? Icons.help_outline,
                      color: _selectedPresentationType == type
                          ? Color(0xFF7400B8)
                          : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _selectedPresentationType == type
                                  ? Color(0xFF7400B8)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: type,
                      groupValue: _selectedPresentationType,
                      activeColor: Color(0xFF7400B8),
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPresentationGoalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your presentation goal determines the structure and techniques needed for maximum impact.',
          style:
              TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        ...['Inform', 'Persuade', 'Entertain', 'Inspire'].map((goal) {
          String description;

          switch (goal) {
            case 'Inform':
              description = 'Educate or explain something to your audience';
              break;
            case 'Persuade':
              description = 'Convince the audience to adopt your viewpoint';
              break;
            case 'Entertain':
              description = 'Amuse or engage the audience';
              break;
            case 'Inspire':
              description = 'Motivate or encourage the audience';
              break;
            default:
              description = '';
          }

          return Card(
            elevation: _selectedPresentationGoal == goal ? 4 : 1,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedPresentationGoal == goal
                    ? Color(0xFF7400B8)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPresentationGoal = goal;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _goalIcons[goal] ?? Icons.help_outline,
                      color: _selectedPresentationGoal == goal
                          ? Color(0xFF7400B8)
                          : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _selectedPresentationGoal == goal
                                  ? Color(0xFF7400B8)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: goal,
                      groupValue: _selectedPresentationGoal,
                      activeColor: Color(0xFF7400B8),
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationGoal = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAudienceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Understanding your audience helps tailor your content and delivery style.',
          style:
              TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        ...['professionals', 'students', 'general_public', 'experts', 'mixed']
            .map((audience) {
          String title;
          String description;

          switch (audience) {
            case 'professionals':
              title = 'Business Professionals';
              description = 'People in professional/corporate settings';
              break;
            case 'students':
              title = 'Students or Learners';
              description = 'Academic or educational context';
              break;
            case 'general_public':
              title = 'General Public';
              description = 'Wide range of backgrounds and knowledge';
              break;
            case 'experts':
              title = 'Subject Matter Experts';
              description = 'Specialized audience with deep knowledge';
              break;
            case 'mixed':
              title = 'Mixed Audience';
              description = 'Diverse backgrounds and knowledge levels';
              break;
            default:
              title = audience;
              description = '';
          }

          return Card(
            elevation: _selectedAudience == audience ? 4 : 1,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedAudience == audience
                    ? Color(0xFF7400B8)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAudience = audience;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _audienceIcons[audience] ?? Icons.people,
                      color: _selectedAudience == audience
                          ? Color(0xFF7400B8)
                          : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _selectedAudience == audience
                                  ? Color(0xFF7400B8)
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: audience,
                      groupValue: _selectedAudience,
                      activeColor: Color(0xFF7400B8),
                      onChanged: (value) {
                        setState(() {
                          _selectedAudience = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTopicInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Briefly describe the topic or subject of your presentation.',
          style:
              TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Color(0xFF7400B8).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Presentation Topic or Subject',
                border: InputBorder.none,
                icon: Icon(Icons.subject, color: Color(0xFF7400B8)),
                hintText: 'E.g., "New Product Launch", "Research Findings"',
              ),
              style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
              maxLines: 3,
              minLines: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your presentation topic';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give your practice session a name to help identify it later.',
          style:
              TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Color(0xFF7400B8).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Session Name',
                border: InputBorder.none,
                icon: Icon(Icons.bookmark, color: Color(0xFF7400B8)),
                hintText: 'E.g., "TED Talk Practice", "Sales Pitch Rehearsal"',
              ),
              style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a session name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedName = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPresentationType == null ||
          _selectedPresentationGoal == null ||
          _selectedAudience == null ||
          _selectedTopic == null ||
          _selectedTopic!.isEmpty ||
          _selectedName == null ||
          _selectedName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Update the provider with all the collected information
        Provider.of<SessionProvider>(context, listen: false).startSession(
            _selectedPresentationType!,
            _selectedPresentationGoal!,
            _selectedName!,
            audience: _selectedAudience!,
            topic: _selectedTopic!);

        // Don't need to call addSession separately as saveToSupabase will handle it
        // Just proceed with saving to Supabase
        await Provider.of<SessionProvider>(context, listen: false)
            .saveToSupabase();

        if (mounted) {
          Navigator.pushNamed(context, '/camera');
        }
      } catch (e) {
        if (mounted) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: Text('An error occurred. Please try again later.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              });
        }
      }
    }
  }
}
