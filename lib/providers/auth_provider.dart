import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  int? _userId;
  String? _name;
  String? _email;
  String? _token;
  Map<String, dynamic>? _stats;
  List<dynamic>? _history;
  bool _isLoading = false;

  int? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get token => _token;
  Map<String, dynamic>? get stats => _stats;
  List<dynamic>? get history => _history;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userId != null && _token != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();
    
    if (await _apiService.isLoggedIn()) {
      final results = await _apiService.getUserResults();
      if (results['success'] == true) {
        final p = await SharedPreferences.getInstance();
        _userId = p.getInt(ApiService.keyUserId);
        _name = p.getString(ApiService.keyUserName);
        _email = p.getString(ApiService.keyUserEmail);
        _token = p.getString(ApiService.keyToken);
        
        await fetchAssessment();
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.registerUser(name, email, password);
    _isLoading = false;
    
    if (result['success'] == true) {
      _userId = result['userId'];
      _name = name;
      _email = email;
      _token = result['token'];
      await _saveEmailToHistory(email);
      await fetchAssessment();
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return result['error'];
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.loginUser(email, password);
    _isLoading = false;
    
    if (result['success'] == true) {
      _userId = result['user']['id'];
      _name = result['user']['name'];
      _email = result['user']['email'];
      _token = result['token'];
      await _saveEmailToHistory(result['user']['email']);
      await fetchAssessment();
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return result['error'];
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _userId = null;
    _name = null;
    _email = null;
    _token = null;
    _stats = null;
    _history = null;
    notifyListeners();
  }

  Future<void> fetchAssessment() async {
    if (!isLoggedIn) return;
    
    try {
      final data = await _apiService.getUserResults();
      if (data['success'] == true) {
        _stats = data['stats'];
        _history = data['history'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching assessment: $e");
    }
  }

  Future<void> saveQuizResult({
    required int score,
    required int attempted,
    required int correct,
    required int wrong,
    required double percentage,
    required String result,
  }) async {
    if (!isLoggedIn) return;

    final success = await _apiService.submitQuiz(
      score: score,
      attempted: attempted,
      correct: correct,
      wrong: wrong,
      percentage: percentage,
      result: result,
    );

    if (success) {
      await fetchAssessment();
    }
  }

  Future<void> _saveEmailToHistory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedEmails = prefs.getStringList('saved_emails') ?? [];
    if (!savedEmails.contains(email)) {
      savedEmails.add(email);
      await prefs.setStringList('saved_emails', savedEmails);
    }
  }

  Future<List<String>> getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saved_emails') ?? [];
  }
}
