import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/traffic_rule.dart';
import '../models/traffic_sign.dart';

class DataService {
  Future<List<Question>> loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/data/questions.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      print("Error loading questions: $e");
      return [];
    }
  }

  Future<List<TrafficRule>> loadRules() async {
    try {
      final String response = await rootBundle.loadString('assets/data/rules.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => TrafficRule.fromJson(json)).toList();
    } catch (e) {
      print("Error loading rules: $e");
      return [];
    }
  }

  Future<List<TrafficSign>> loadSigns() async {
    try {
      final String response = await rootBundle.loadString('assets/data/signs.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => TrafficSign.fromJson(json)).toList();
    } catch (e) {
      print("Error loading signs: $e");
      return [];
    }
  }
}
