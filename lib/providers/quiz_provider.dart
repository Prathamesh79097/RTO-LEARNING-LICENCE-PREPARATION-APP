import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const String _keySeenIds = 'seen_question_ids';
  
  List<Question> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _attemptedQuestions = 0;
  bool _isQuizActive = false;
  bool _isLoading = false;
  List<int> _recentQuestionIds = [];

  List<Question> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get attemptedQuestions => _attemptedQuestions;
  bool get isQuizActive => _isQuizActive;
  bool get isLoading => _isLoading;

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
