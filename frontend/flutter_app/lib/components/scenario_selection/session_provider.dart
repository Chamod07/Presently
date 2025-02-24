import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier{
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;
  List<String> _sessions = [];

  List<String> get sessions => _sessions;
  String? get selectedPresentationType => _selectedPresentationType;
  String? get selectedPresentationGoal => _selectedPresentationGoal;
  String? get selectedName => _selectedName;

  //session data update
  void startSession(String presentationType, String presentationGoal, String sessionName){
    _selectedPresentationType = presentationType;
    _selectedPresentationGoal = presentationGoal;
    _selectedName = sessionName;
    notifyListeners();
  }
  void addSession(String session){
    _sessions.add(session);
    notifyListeners();
  }

  //clear session data
  void clearSession(){
    _selectedPresentationType = null;
    _selectedPresentationGoal = null;
    _selectedName = null;
    notifyListeners();
  }
}