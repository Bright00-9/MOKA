import 'package:flutter/material.dart';
import '../../core/services/applications_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = ApplicationsService.myApplications();
  }

  void _refresh() => setState(() => _applicationsFuture = ApplicationsService.myApplications());

  Color _statusColor(String status) => switch (status) {
        'PENDING_PAYMENT' => Colors.grey,
        'APPLIED' => Colors.blue,
        'ACCEPTED' => Colors.green,
        'REJECTED' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _applicationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load your applications. Pull to retry.'));
            }
            final applications = snapshot.data ?? [];
            if (applications.isEmpty) {
              return const Center(child: Text('You haven\'t applied to any jobs yet.'));
            }
            return ListView.separated(
              itemCount: applications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final app = applications[i];
                final job = app['job'] as Map<String, dynamic>?;
                return ListTile(
                  title: Text(job?['title'] as String? ?? 'Job'),
                  subtitle: Text('${job?['category'] ?? ''} · ${job?['location'] ?? ''}'),
                  trailing: Chip(
                    label: Text(app['status'] as String, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: _statusColor(app['status'] as String),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
