import 'package:flutter/material.dart';

class ScenarioSelection extends StatefulWidget {
  const ScenarioSelection({super.key});

  @override
  _ScenarioSelectionScreenState createState() => _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelection> {
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Let\'s get ready'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. What type of presentation are you preparing for?'),
            SizedBox(height: 8.0),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    title: Text('Business Presentation'),
                    value: 'business',
                    groupValue: _selectedPresentationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationType = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Academic Presentation'),
                    value: 'academic',
                    groupValue: _selectedPresentationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationType = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Public Speaking Event'),
                    value: 'pub_speaking',
                    groupValue: _selectedPresentationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationType = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Interview or Job Talks'),
                    value: 'interview',
                    groupValue: _selectedPresentationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationType = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Casual Speech'),
                    value: 'casual',
                    groupValue: _selectedPresentationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationType = value;
                      });
                    },
                  ),

                ],
              ),
            ),
            SizedBox(height: 16.0),
            Text('2. What\'s the goal of your presentation?'),
            SizedBox(height: 8.0),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  RadioListTile<String>(
                    title: Text('Inform'),
                    value: 'inform',
                    groupValue: _selectedPresentationGoal,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationGoal = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Persuade'),
                    value: 'Persuade',
                    groupValue: _selectedPresentationGoal,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationGoal = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Entertain'),
                    value: 'Entertain',
                    groupValue: _selectedPresentationGoal,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationGoal = value;
                      });
                    },
                  ),

                  RadioListTile<String>(
                    title: Text('Inspire'),
                    value: 'Inspire',
                    groupValue: _selectedPresentationGoal,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresentationGoal = value;
                      });
                    },
                  ),



                  // Add more RadioListTile widgets for other presentation goals
                ],
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // Handle form submission and navigation to the next screen
                print('Selected presentation type: $_selectedPresentationType');
                print('Selected presentation goal: $_selectedPresentationGoal');
                Navigator.pushNamed(context, '/camera');
              },
              child: Text('Get started'),

            ),
          ],
        ),
        // ),
      ),
    );
  }
}
