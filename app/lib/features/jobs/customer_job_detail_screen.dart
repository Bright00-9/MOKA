import 'package:flutter/material.dart';
import '../../core/services/jobs_service.dart';

class CustomerJobDetailScreen extends StatefulWidget {
  final String jobId;
  const CustomerJobDetailScreen({super.key, required this.jobId});

  @override
  State<CustomerJobDetailScreen> createState() => _CustomerJobDetailScreenState();
}

class _CustomerJobDetailScreenState extends State<CustomerJobDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  String? _actingOnApplicationId;

  @override
  void initState() {
    super.initState();
    _detailFuture = JobsService.jobDetail(widget.jobId);
  }

  void _refresh() => setState(() => _detailFuture = JobsService.jobDetail(widget.jobId));

  Future<void> _decide(String applicationId, String decision) async {
    setState(() => _actingOnApplicationId = applicationId);
    try {
      await JobsService.decideApplication(applicationId, decision);
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not record your decision. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _actingOnApplicationId = null);
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
          final applications = (job['applications'] as List?) ?? [];

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(job['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(job['description'] as String),
                const SizedBox(height: 8),
                Text('${job['category']} · ${job['location']} · Status: ${job['status']}',
                    style: TextStyle(color: Colors.grey.shade700)),
                const Divider(height: 32),
                Text('Applications (${applications.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (applications.isEmpty)
                  const Text('No paid applications yet. Providers see this job once posted.'),
                ...applications.map((app) {
                  final provider = app['provider'] as Map<String, dynamic>;
                  final isActing = _actingOnApplicationId == app['id'];
                  return Card(
                    child: ListTile(
                      title: Text(provider['fullName'] as String),
                      subtitle: Text(
                          'Tier ${provider['starLevel']} · ${provider['verified'] == true ? 'Verified' : 'Unverified'}'
                          '${app['message'] != null ? '\n${app['message']}' : ''}'),
                      isThreeLine: app['message'] != null,
                      trailing: job['status'] == 'OPEN'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: isActing ? null : () => _decide(app['id'] as String, 'ACCEPTED'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: isActing ? null : () => _decide(app['id'] as String, 'REJECTED'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
