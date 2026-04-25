import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const String _keySeenIds = 'seen_question_ids';
  
  List<Question> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isQuizActive = false;
  bool _isLoading = false;
  List<int> _recentQuestionIds = [];
  Map<int, String> _userAnswers = {};

  List<Question> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isQuizActive => _isQuizActive;
  bool get isLoading => _isLoading;
  String? getUserAnswer(int index) => _userAnswers[index];

  QuizProvider() {
    _loadSeenIds();
  }

  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedIds = prefs.getStringList(_keySeenIds) ?? [];
    _recentQuestionIds = savedIds.map(int.parse).toList();
  }

  Future<void> _saveSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only the last 30 questions (about 2 quizzes) to ensure variety
    if (_recentQuestionIds.length > 30) {
      _recentQuestionIds = _recentQuestionIds.sublist(_recentQuestionIds.length - 30);
    }
    await prefs.setStringList(_keySeenIds, _recentQuestionIds.map((id) => id.toString()).toList());
  }
  
  Question? get currentQuestion {
    if (_quizQuestions.isNotEmpty && _currentQuestionIndex < _quizQuestions.length) {
      return _quizQuestions[_currentQuestionIndex];
    }
    return null;
  }

  // Fetch 15 random questions from backend, avoiding recent ones
  Future<void> fetchQuiz() async {
    _isLoading = true;
    _isQuizActive = false;
    notifyListeners();

    try {
      // Refresh seen IDs before fetching
      await _loadSeenIds();
      
      _quizQuestions = await _apiService.fetchQuiz(excludeIds: _recentQuestionIds);
      
      // Add new IDs to the seen list
      final newIds = _quizQuestions.where((q) => q.id != null).map((q) => q.id!).toList();
      _recentQuestionIds.addAll(newIds);
      await _saveSeenIds();

      _currentQuestionIndex = 0;
      _userAnswers = {};
      _isQuizActive = true;
    } catch (e) {
      debugPrint("Error fetching quiz: $e");
      _quizQuestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(String selectedOption) {
    if (!_isQuizActive) return;
    _userAnswers[_currentQuestionIndex] = selectedOption;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  // Legacy method kept for compatibility if needed, but updated
  void answerQuestion(String selectedOption) {
    selectAnswer(selectedOption);
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      nextQuestion();
    } else {
      _isQuizActive = false;
    }
  }

  void endQuizEarly() {
    _isQuizActive = false;
    notifyListeners();
  }

  void completeQuiz() {
    endQuizEarly();
  }
  
  void resetQuiz() {
    _isQuizActive = false;
    _quizQuestions = [];
    _currentQuestionIndex = 0;
    _userAnswers = {};
    notifyListeners();
  }

  // Calculate score dynamically
  int get score {
    int s = 0;
    _userAnswers.forEach((index, answer) {
      if (index < _quizQuestions.length && answer == _quizQuestions[index].answer) {
        s++;
      }
    });
    return s;
  }

  int get attemptedQuestions => _userAnswers.length;

  // Calculate if PASS (>= 9 correct)
  bool get isPass => score >= 9;
}
