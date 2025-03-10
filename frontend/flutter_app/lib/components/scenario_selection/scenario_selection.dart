import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';

class ScenarioSelection extends StatefulWidget {
  const ScenarioSelection({super.key});

  @override
  _ScenarioSelectionScreenState createState() => _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelection> {
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Let\'s get ready',
          style: TextStyle(fontSize: 24, fontFamily: 'Roboto' ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. What type of presentation are you preparing for?',
                style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
              ),
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
                      title: Text('Business Presentation',
                        style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
                      ),
                      value: 'business',
                      groupValue: _selectedPresentationType,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationType = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Academic Presentation',
                        style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
                      ),
                      value: 'academic',
                      groupValue: _selectedPresentationType,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationType = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Public Speaking Event',
                        style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
                      ),
                      value: 'pub_speaking',
                      groupValue: _selectedPresentationType,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationType = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Interview or Job Talks',
                        style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
                      ),
                      value: 'interview',
                      groupValue: _selectedPresentationType,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationType = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Casual Speech',
                        style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
                      ),
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
              Text('2. What\'s the goal of your presentation?',
                style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
              ),
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
                      title: Text('Inform',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
                      ),
                      value: 'inform',
                      groupValue: _selectedPresentationGoal,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationGoal = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Persuade',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
                      ),
                      value: 'Persuade',
                      groupValue: _selectedPresentationGoal,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationGoal = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Entertain',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
                      ),
                      value: 'Entertain',
                      groupValue: _selectedPresentationGoal,
                      onChanged: (value) {
                        setState(() {
                          _selectedPresentationGoal = value;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: Text('Inspire',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
                      ),
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


              SizedBox(height: 16.0),
              Text('3. Please provide a name for your session.',
                style: TextStyle(fontSize: 17, fontFamily: 'Roboto'),
              ),
              SizedBox(height: 8.0),
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter session name',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 17),
                  onChanged: (value) {
                    setState(() {
                      _selectedName = value; // Store the input value
                    });
                  },
                ),
              ),

              ElevatedButton(
                onPressed: () async {
                  // Handle form submission and navigation to the next screen
                  print('Selected presentation type: $_selectedPresentationType');
                  print('Selected presentation goal: $_selectedPresentationGoal');
                  print('Selected presentation goal: $_selectedName');
                  Provider.of<SessionProvider>(context, listen: false)
                      .startSession(_selectedPresentationType!, _selectedPresentationGoal!, _selectedName!);
                  Provider.of<SessionProvider>(context, listen: false)
                      .addSession('$_selectedName'); // Add session to the list
                  try{
                    await Provider.of<SessionProvider>(context, listen: false)
                        .saveToSupabase();

                    if (mounted){
                      Navigator.pushNamed(context, '/camera');
                    }
                  }
                  catch (e){
                    if(mounted){
                      showDialog(
                        context: context,
                        builder: (BuildContext context){
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
                        }
                      );
                    }
                  }

                }, style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                backgroundColor: Color(0xFF7400B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
                child: Text('Get started',
                    style: TextStyle(fontSize: 17, color: Colors.white, fontFamily: 'Roboto')
                ),
              ),
            ],
          ),
          // ),
        ),
      ),
    );
  }
}