import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';

class QuizProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Question> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _attemptedQuestions = 0;
  bool _isQuizActive = false;
  bool _isLoading = false;

  List<Question> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get attemptedQuestions => _attemptedQuestions;
  bool get isQuizActive => _isQuizActive;
  bool get isLoading => _isLoading;
  
  Question? get currentQuestion {
    if (_quizQuestions.isNotEmpty && _currentQuestionIndex < _quizQuestions.length) {
      return _quizQuestions[_currentQuestionIndex];
    }
    return null;
  }

  // Fetch 15 random questions from backend
  Future<void> fetchQuiz() async {
    _isLoading = true;
    _isQuizActive = false;
    notifyListeners();

    try {
      _quizQuestions = await _apiService.fetchQuiz();
      _currentQuestionIndex = 0;
      _score = 0;
      _attemptedQuestions = 0;
      _isQuizActive = true;
    } catch (e) {
      debugPrint("Error fetching quiz: $e");
      _quizQuestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Calculate if PASS (>= 9 correct)
  bool get isPass => _score >= 9;
}
