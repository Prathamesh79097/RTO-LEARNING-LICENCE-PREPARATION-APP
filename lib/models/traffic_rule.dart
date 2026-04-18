class TrafficRule {
  final String title;
  final String description;

  TrafficRule({
    required this.title,
    required this.description,
  });

  factory TrafficRule.fromJson(Map<String, dynamic> json) {
    return TrafficRule(
      title: json['title'],
      description: json['description'],
    );
  }
}
