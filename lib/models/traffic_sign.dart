class TrafficSign {
  final String name;
  final String image;
  final String description;

  TrafficSign({
    required this.name,
    required this.image,
    required this.description,
  });

  factory TrafficSign.fromJson(Map<String, dynamic> json) {
    return TrafficSign(
      name: json['name'],
      image: json['image'],
      description: json['description'],
    );
  }
}
