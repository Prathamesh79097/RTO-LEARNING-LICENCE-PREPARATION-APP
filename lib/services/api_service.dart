import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/question.dart';

class ApiService {
  static const String baseUrl = "https://rto-learning-licence-preparation-app.onrender.com/api";

  // Shared preferences keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(keyToken);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Login
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyToken, data['token']);
        await prefs.setInt(keyUserId, data['user']['id']);
        await prefs.setString(keyUserName, data['user']['name']);
        await prefs.setString(keyUserEmail, data['user']['email']);
        return data;
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Server not reachable. Try again later.'};
    }
  }

  // 2. Register
  Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyToken, data['token']);
        await prefs.setInt(keyUserId, data['userId']);
        await prefs.setString(keyUserName, name);
        await prefs.setString(keyUserEmail, email);
        return data;
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Server not reachable. Try again later.'};
    }
  }

  // 3. Fetch Quiz (15 random questions)
  Future<List<Question>> fetchQuiz({List<int>? excludeIds}) async {
    try {
      String url = '$baseUrl/quiz';
      if (excludeIds != null && excludeIds.isNotEmpty) {
        url += '?exclude=${excludeIds.join(',')}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['questions'] as List)
              .map((q) => Question.fromJson(q))
              .toList();
        }
      }
      throw Exception('Failed to fetch quiz');
    } catch (e) {
      rethrow;
    }
  }

  // 4. Submit Quiz Result
  Future<bool> submitQuiz({
    required int score,
    required int attempted,
    required int correct,
    required int wrong,
    required double percentage,
    required String result,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submit-quiz'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'score': score,
          'attempted': attempted,
          'correct': correct,
          'wrong': wrong,
          'percentage': percentage,
          'result': result,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 5. Get User Results History
  Future<Map<String, dynamic>> getUserResults() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/results'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch results');
    } catch (e) {
      rethrow;
    }
  }
  
  // 6. Delete Quiz Attempt
  Future<bool> deleteQuizAttempt(int attemptId) async {
    try {
      final url = Uri.parse('$baseUrl/quiz-attempt/$attemptId');
      debugPrint("Attempting to delete: $url");
      
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      );
      
      debugPrint("Delete response: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Error during delete: $e");
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check login status
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(keyToken);
  }
}
