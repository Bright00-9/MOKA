class JobApplication {
  final String id;
  final String jobId;
  final String status; // PENDING_PAYMENT | APPLIED | ACCEPTED | REJECTED | WITHDRAWN
  final String? message;
  final Map<String, dynamic>? job; // populated on some endpoints

  JobApplication({required this.id, required this.jobId, required this.status, this.message, this.job});

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        status: json['status'] as String,
        message: json['message'] as String?,
        job: json['job'] as Map<String, dynamic>?,
      );
}
