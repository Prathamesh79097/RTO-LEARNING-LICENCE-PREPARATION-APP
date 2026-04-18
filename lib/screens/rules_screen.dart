import 'package:flutter/material.dart';
import '../models/traffic_rule.dart';
import '../services/data_service.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  List<TrafficRule> rules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() async {
    final service = DataService();
    final loadedRules = await service.loadRules();
    setState(() {
      rules = loadedRules;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Rules'),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(rule.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(rule.description, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
