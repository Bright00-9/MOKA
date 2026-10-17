import 'api_client.dart';

class ApplicationsService {
  /// Initiates the pay-to-apply flow. Always requires payment (unlike star-tier
  /// unlocks, which can be free at tier 1) — the flat application fee applies to
  /// every job, every tier.
  static Future<({String authorizationUrl, String reference})> apply(String jobId, {String? message}) async {
    final res = await ApiClient.instance.client
        .post('/jobs/$jobId/applications', data: {if (message != null) 'message': message});
    final payment = res.data['payment'] as Map<String, dynamic>;
    return (authorizationUrl: payment['authorizationUrl'] as String, reference: payment['reference'] as String);
  }

  static Future<List<Map<String, dynamic>>> myApplications() async {
    final res = await ApiClient.instance.client.get('/applications/mine');
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
