import 'package:flutter/material.dart';
import '../../core/models/job.dart';
import '../../core/services/jobs_service.dart';
import 'customer_job_detail_screen.dart';
import 'post_job_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late Future<List<Job>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = JobsService.myJobs();
  }

  void _refresh() => setState(() => _jobsFuture = JobsService.myJobs());

  Color _statusColor(String status) => switch (status) {
        'OPEN' => Colors.blue,
        'ASSIGNED' => Colors.orange,
        'COMPLETED' => Colors.green,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My jobs')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Job>>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load your jobs. Pull to retry.'));
            }
            final jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return const Center(child: Text('No jobs posted yet. Tap + to post one.'));
            }
            return ListView.separated(
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final job = jobs[i];
                return ListTile(
                  title: Text(job.title),
                  subtitle: Text('${job.category} · ${job.location} · ${job.applicationCount} applicant(s)'),
                  trailing: Chip(
                    label: Text(job.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: _statusColor(job.status),
                  ),
                  onTap: () async {
                    await Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => CustomerJobDetailScreen(jobId: job.id)));
                    _refresh();
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PostJobScreen()),
          );
          if (posted == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
