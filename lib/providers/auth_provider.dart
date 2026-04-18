import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  int? _userId;
  String? _name;
  String? _email;
  String? _token; // JWT Token
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

  // Dynamic base URL to handle different environments (Emulator, Physical Device, Web)
  String get baseUrl {
    const String defaultUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');
    
    // Automatically use 10.0.2.2 for Android Emulator if localhost is specified
    if (!kIsWeb && Platform.isAndroid && defaultUrl.contains('localhost')) {
      return defaultUrl.replaceFirst('localhost', '10.0.2.2');
    }
    
    // TIP: If you are using a physical device, replace 'localhost' with your computer's IP: 192.168.29.203
    return defaultUrl;
  }

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    _name = prefs.getString('user_name');
    _email = prefs.getString('user_email');
    _token = prefs.getString('auth_token');
    
    if (isLoggedIn) {
      await fetchAssessment();
    }
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<String?> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _userId = data['userId'];
        _name = name;
        _email = email;
        _token = data['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', _userId!);
        await prefs.setString('user_name', _name!);
        await prefs.setString('user_email', _email!);
        await prefs.setString('auth_token', _token!);
        
        await _saveEmailToHistory(_email!);
        
        await fetchAssessment();
        return null; // success
      } else {
        return data['error'] ?? 'Registration failed';
      }
    } catch (e) {
      return "Unable to connect to the server ($baseUrl). Please ensure the backend server is running and your device has network access.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _userId = data['user']['id'];
        _name = data['user']['name'];
        _email = data['user']['email'];
        _token = data['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', _userId!);
        await prefs.setString('user_name', _name!);
        await prefs.setString('user_email', _email!);
        await prefs.setString('auth_token', _token!);
        
        await _saveEmailToHistory(_email!);
        
        await fetchAssessment();
        return null; // success
      } else {
        return data['error'] ?? 'Login failed';
      }
    } catch (e) {
      return "Unable to connect to the server ($baseUrl). Please ensure the backend server is running and your device has network access.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _userId = null;
    _name = null;
    _email = null;
    _token = null;
    _stats = null;
    _history = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('auth_token');
    
    notifyListeners();
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

  Future<void> fetchAssessment() async {
    if (!isLoggedIn) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getUserResults/$_userId'),
        headers: _authHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _stats = data['stats'];
        _history = data['history'];
        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid
        await logout();
      }
    } catch (e) {
      print("Error fetching assessment: $e");
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saveQuizResult'),
        headers: _authHeaders,
        body: json.encode({
          // Notice we don't send `user_id` here anymore because the backend reads it securely from the JWT token!
          'score': score,
          'attempted': attempted,
          'correct': correct,
          'wrong': wrong,
          'percentage': percentage,
          'result': result,
        }),
      );

      if (response.statusCode == 200) {
        await fetchAssessment(); // Refresh dashboard data
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired or invalid
        await logout();
      }
    } catch (e) {
      print("Error saving quiz result: $e");
    }
  }
}
