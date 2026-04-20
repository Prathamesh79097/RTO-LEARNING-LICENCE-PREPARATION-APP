import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveScore();
    });
  }

  void _saveScore() {
    if (_scoreSaved) return;
    _scoreSaved = true;

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final score = quizProvider.score;
    final attempted = quizProvider.attemptedQuestions;
    final total = quizProvider.quizQuestions.length; // usually 15
    final correct = score;
    final wrong = attempted - score;
    double percentage = total > 0 ? (score / total) * 100 : 0.0;
    final isPassed = score >= 9;

    authProvider.saveQuizResult(
      score: score,
      attempted: attempted,
      correct: correct,
      wrong: wrong,
      percentage: percentage,
      result: isPassed ? 'PASS' : 'FAIL',
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    
    final score = quizProvider.score;
    final total = quizProvider.quizQuestions.length;
    final attempted = quizProvider.attemptedQuestions;
    final isPassed = score >= 9;
    
    String message = "";
    Color headerColor = Colors.grey;
    IconData icon = Icons.info;
    
    if (attempted < total && attempted <= 0) {
       message = "Quiz ended early because you left the test.";
       headerColor = Colors.orange;
       icon = Icons.warning_amber_rounded;
    } else if (isPassed) {
       message = "Congratulations! You are ready for RTO test \uD83D\uDE97";
       headerColor = Colors.green;
       icon = Icons.check_circle;
    } else {
       message = "You need more practice. Try again!";
       headerColor = Colors.red;
       icon = Icons.cancel;
    }

    String badge = "Needs Improvement \u26A0\uFE0F";
    if (score >= 12) {
      badge = "Excellent \u2B50";
    } else if (score >= 9) {
      badge = "Good \uD83D\uDC4D";
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Result'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 100, color: headerColor),
                const SizedBox(height: 24),
                Text(
                  isPassed ? "PASS" : "FAIL",
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold, 
                    color: headerColor,
                    letterSpacing: 2
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text('Score: $score / $total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildStatRow('Attempted:', '$attempted', Colors.blue),
                        const SizedBox(height: 8),
                        _buildStatRow('Correct:', '$score', Colors.green),
                        const SizedBox(height: 8),
                        _buildStatRow('Wrong:', '${attempted - score}', Colors.red),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildStatRow('Percentage:', '${((score/total)*100).toStringAsFixed(1)}%', Colors.purple),
                        const SizedBox(height: 8),
                        _buildStatRow('Performance:', badge, Colors.orange),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
