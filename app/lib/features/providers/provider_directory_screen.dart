import 'package:flutter/material.dart';
import '../../core/models/provider_profile.dart';
import '../../core/services/providers_service.dart';
import '../payments/paystack_checkout_screen.dart';

// Must match PLATFORM_CALLBACK_URL configured on the backend.
const String _callbackUrlPrefix = 'https://moka.example.com/payment-callback';

class ProviderDirectoryScreen extends StatefulWidget {
  const ProviderDirectoryScreen({super.key});

  @override
  State<ProviderDirectoryScreen> createState() => _ProviderDirectoryScreenState();
}

class _ProviderDirectoryScreenState extends State<ProviderDirectoryScreen> {
  int? _selectedTier;
  late Future<List<ProviderProfile>> _providersFuture;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _providersFuture = ProvidersService.browse();
  }

  void _filterByTier(int? tier) {
    setState(() {
      _selectedTier = tier;
      _providersFuture = ProvidersService.browse(starLevel: tier);
    });
  }

  Future<void> _unlockTier(int tier) async {
    setState(() => _unlocking = true);
    try {
      final checkout = await ProvidersService.initiateUnlock(tier);
      if (checkout == null) {
        // Free tier — already unlocked server-side.
        _filterByTier(tier);
        return;
      }
      if (!mounted) return;
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutScreen(
            authorizationUrl: checkout.authorizationUrl,
            reference: checkout.reference,
            callbackUrlPrefix: _callbackUrlPrefix,
          ),
        ),
      );
      if (success == true) {
        _filterByTier(tier); // reload — contact details now unlocked for this tier
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment was not confirmed. No charge was applied.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not start payment. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find providers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All tiers'),
                  selected: _selectedTier == null,
                  onSelected: (_) => _filterByTier(null),
                ),
                ...List.generate(5, (i) => i + 1).map(
                  (tier) => ChoiceChip(
                    label: Text('Tier $tier'),
                    selected: _selectedTier == tier,
                    onSelected: (_) => _filterByTier(tier),
                  ),
                ),
              ],
            ),
          ),
          if (_unlocking) const LinearProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<ProviderProfile>>(
              future: _providersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final providers = snapshot.data ?? [];
                if (providers.isEmpty) {
                  return const Center(child: Text('No providers found for this tier yet.'));
                }
                return ListView.separated(
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = providers[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${p.starLevel ?? '-'}★')),
                      title: Text(p.fullName),
                      subtitle: Text(p.skills.isNotEmpty ? p.skills.join(', ') : (p.bio ?? '')),
                      trailing: p.contactUnlocked
                          ? const Icon(Icons.lock_open, color: Colors.green)
                          : TextButton(
                              onPressed: () => _unlockTier(p.starLevel ?? 1),
                              child: const Text('Unlock'),
                            ),
                      onTap: p.contactUnlocked
                          ? () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(p.fullName),
                                  content: Text('Email: ${p.email ?? '-'}\nPhone: ${p.phone ?? '-'}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
