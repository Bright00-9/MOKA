class Job {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final int? budgetMin;
  final int? budgetMax;
  final int? requiredStarLevel;
  final String status; // OPEN | ASSIGNED | COMPLETED | CANCELLED
  final int applicationCount;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.budgetMin,
    this.budgetMax,
    this.requiredStarLevel,
    required this.status,
    this.applicationCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        location: json['location'] as String,
        budgetMin: json['budgetMin'] as int?,
        budgetMax: json['budgetMax'] as int?,
        requiredStarLevel: json['requiredStarLevel'] as int?,
        status: json['status'] as String,
        applicationCount: (json['_count']?['applications'] as int?) ?? 0,
      );
}
