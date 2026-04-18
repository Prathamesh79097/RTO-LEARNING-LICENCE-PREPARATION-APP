import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/data_service.dart';

class QuizProvider with ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Question> _quizQuestions = [];
  
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _attemptedQuestions = 0;
  bool _isQuizActive = false;

  List<Question> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get attemptedQuestions => _attemptedQuestions;
  bool get isQuizActive => _isQuizActive;
  
  Question? get currentQuestion {
    if (_quizQuestions.isNotEmpty && _currentQuestionIndex < _quizQuestions.length) {
      return _quizQuestions[_currentQuestionIndex];
    }
    return null;
  }

  Future<void> loadQuestions() async {
    final dataService = DataService();
    _allQuestions = await dataService.loadQuestions();
    notifyListeners();
  }

  void startQuiz() {
    if (_allQuestions.isEmpty) return;
    
    // Shuffle and pick 15
    _allQuestions.shuffle();
    _quizQuestions = _allQuestions.take(15).toList();
    
    _currentQuestionIndex = 0;
    _score = 0;
    _attemptedQuestions = 0;
    _isQuizActive = true;
    notifyListeners();
  }

  void answerQuestion(String selectedOption) {
    if (!_isQuizActive) return;

    if (currentQuestion != null && selectedOption == currentQuestion!.answer) {
      _score++;
    }
    
    _attemptedQuestions++;

    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _isQuizActive = false; // Quiz finished naturally
    }
    notifyListeners();
  }

  void endQuizEarly() {
    _isQuizActive = false;
    notifyListeners();
  }
  
  void resetQuiz() {
    _isQuizActive = false;
    _quizQuestions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _attemptedQuestions = 0;
    notifyListeners();
  }
}
