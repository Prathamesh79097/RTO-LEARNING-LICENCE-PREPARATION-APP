class Question {
  final int? id;
  final String question;
  final List<String> options;
  final String answer;
  final String? image;

  Question({
    this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.image,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'] ?? 'Unknown',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
      image: json['image'],
    );
  }
}
