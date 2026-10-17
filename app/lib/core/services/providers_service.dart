import '../models/provider_profile.dart';
import 'api_client.dart';

class ProvidersService {
  static Future<List<ProviderProfile>> browse({int? starLevel}) async {
    final res = await ApiClient.instance.client.get('/users/providers',
        queryParameters: starLevel != null ? {'starLevel': starLevel} : null);
    return (res.data as List).map((e) => ProviderProfile.fromJson(e)).toList();
  }

  /// Initiates a star-tier unlock. Returns null when the tier was free (tier 1,
  /// no payment needed) — otherwise returns the Paystack authorization URL + reference
  /// for the checkout webview to open.
  static Future<({String authorizationUrl, String reference})?> initiateUnlock(int starLevel) async {
    final res = await ApiClient.instance.client.post('/unlocks', data: {'starLevel': starLevel});
    if (res.data['requiresPayment'] == false) return null;
    final payment = res.data['payment'] as Map<String, dynamic>;
    return (authorizationUrl: payment['authorizationUrl'] as String, reference: payment['reference'] as String);
  }
}
