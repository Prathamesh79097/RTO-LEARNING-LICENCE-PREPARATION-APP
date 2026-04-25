import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? selectedOption;
  bool _isInitialized = false;

  void _showExitWarningDialog(BuildContext context, QuizProvider quizProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Leave Quiz?'),
        content: const Text('Leaving the quiz will end your test. Do you want to continue and see your results?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO, STAY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              quizProvider.endQuizEarly();
              Navigator.pushReplacementNamed(context, '/result'); // Go to result
            },
            child: const Text('YES, END TEST'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        if (!_isInitialized && quizProvider.isQuizActive) {
          selectedOption = quizProvider.getUserAnswer(quizProvider.currentQuestionIndex);
          _isInitialized = true;
        }

        final currentQuestion = quizProvider.currentQuestion;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
             if (didPop) return;
             if (quizProvider.isQuizActive) {
               _showExitWarningDialog(context, quizProvider);
             } else {
               Navigator.pop(context);
             }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mock Test'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showExitWarningDialog(context, quizProvider),
                )
              ],
            ),
            body: currentQuestion == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress Bar
                        LinearProgressIndicator(
                          value: (quizProvider.currentQuestionIndex + 1) / quizProvider.quizQuestions.length,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: Colors.grey[300],
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Question ${quizProvider.currentQuestionIndex + 1} of ${quizProvider.quizQuestions.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  currentQuestion.question,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                if (currentQuestion.image != null) ...[
                                  const SizedBox(height: 20),
                                  Image.network(
                                    currentQuestion.image!,
                                    height: 150,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                ],
                                const SizedBox(height: 40),
                                
                                ...currentQuestion.options.map((option) {
                                  final isSelected = selectedOption == option;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedOption = option;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected 
                                              ? Theme.of(context).colorScheme.primary 
                                              : Colors.grey.withValues(alpha: 0.5),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          color: isSelected 
                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                            : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                option, 
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Previous Button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: quizProvider.currentQuestionIndex == 0
                                    ? null
                                    : () {
                                        if (selectedOption != null) {
                                          quizProvider.selectAnswer(selectedOption!);
                                        }
                                        quizProvider.previousQuestion();
                                        setState(() {
                                          selectedOption = quizProvider.getUserAnswer(quizProvider.currentQuestionIndex);
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                child: const Text('Previous', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Next/Finish Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedOption == null
                                    ? null
                                    : () {
                                        quizProvider.selectAnswer(selectedOption!);
                                        
                                        if (quizProvider.currentQuestionIndex == quizProvider.quizQuestions.length - 1) {
                                          quizProvider.completeQuiz();
                                          Navigator.pushReplacementNamed(context, '/result');
                                        } else {
                                          quizProvider.nextQuestion();
                                          setState(() {
                                            selectedOption = quizProvider.getUserAnswer(quizProvider.currentQuestionIndex);
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                child: Text(
                                  quizProvider.currentQuestionIndex == quizProvider.quizQuestions.length - 1
                                      ? 'Finish Test'
                                      : 'Next Question',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
