import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier{
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  List<String> _sessions = [];

  List<String> get sessions => _sessions;
  String? get selectedPresentationType => _selectedPresentationType;
  String? get selectedPresentationGoal => _selectedPresentationGoal;

  //session data update
  void startSession(String presentationType, String presentationGoal){
    _selectedPresentationType = presentationType;
    _selectedPresentationGoal = presentationGoal;
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
    notifyListeners();
  }
}