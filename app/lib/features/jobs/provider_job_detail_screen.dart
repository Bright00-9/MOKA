import 'package:flutter/material.dart';
import '../../core/services/jobs_service.dart';
import '../../core/services/applications_service.dart';
import '../payments/paystack_checkout_screen.dart';

// Must match PLATFORM_CALLBACK_URL configured on the backend.
const String _callbackUrlPrefix = 'https://moka.example.com/payment-callback';

class ProviderJobDetailScreen extends StatefulWidget {
  final String jobId;
  const ProviderJobDetailScreen({super.key, required this.jobId});

  @override
  State<ProviderJobDetailScreen> createState() => _ProviderJobDetailScreenState();
}

class _ProviderJobDetailScreenState extends State<ProviderJobDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  final _messageController = TextEditingController();
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = JobsService.jobDetail(widget.jobId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final checkout = await ApplicationsService.apply(
        widget.jobId,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
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
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Application submitted!')));
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment was not confirmed. Application not submitted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('already applied')
              ? 'You already applied to this job.'
              : 'Could not start payment. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Could not load this job.'));
          }
          final job = snapshot.data!;
          final myApplications = (job['applications'] as List?) ?? [];
          final alreadyApplied = myApplications.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(job['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(job['description'] as String),
                const SizedBox(height: 8),
                Text('${job['category']} · ${job['location']}', style: TextStyle(color: Colors.grey.shade700)),
                if (job['requiredStarLevel'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Requires tier ${job['requiredStarLevel']}+',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  ),
                const Divider(height: 32),
                if (alreadyApplied)
                  Text('Your application status: ${myApplications.first['status']}',
                      style: const TextStyle(fontWeight: FontWeight.w600))
                else ...[
                  const Text('A flat platform fee applies when you submit an application. '
                      'This fee goes to Moka, not the customer — payment is required for every application.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message to customer (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _applying ? null : _apply,
                    child: _applying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Pay & apply'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
