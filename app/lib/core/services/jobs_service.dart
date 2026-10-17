import '../models/job.dart';
import 'api_client.dart';

class JobsService {
  // --- Customer methods ---

  static Future<Job> createJob({
    required String title,
    required String description,
    required String category,
    required String location,
    int? budgetMin,
    int? budgetMax,
    int? requiredStarLevel,
  }) async {
    final res = await ApiClient.instance.client.post('/jobs', data: {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      if (budgetMin != null) 'budgetMin': budgetMin,
      if (budgetMax != null) 'budgetMax': budgetMax,
      if (requiredStarLevel != null) 'requiredStarLevel': requiredStarLevel,
    });
    return Job.fromJson(res.data);
  }

  static Future<List<Job>> myJobs() async {
    final res = await ApiClient.instance.client.get('/jobs');
    return (res.data as List).map((e) => Job.fromJson(e)).toList();
  }

  static Future<void> decideApplication(String applicationId, String decision) {
    return ApiClient.instance.client
        .patch('/applications/$applicationId/decision', data: {'decision': decision});
  }

  // --- Provider methods ---

  static Future<List<Job>> browseOpenJobs({String? category}) async {
    final res = await ApiClient.instance.client
        .get('/jobs', queryParameters: {'status': 'OPEN', if (category != null) 'category': category});
    return (res.data as List).map((e) => Job.fromJson(e)).toList();
  }

  // --- Shared ---

  static Future<Map<String, dynamic>> jobDetail(String jobId) async {
    final res = await ApiClient.instance.client.get('/jobs/$jobId');
    return res.data as Map<String, dynamic>;
  }
}
