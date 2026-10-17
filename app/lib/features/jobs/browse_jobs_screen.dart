import 'package:flutter/material.dart';
import '../../core/models/job.dart';
import '../../core/services/jobs_service.dart';
import 'provider_job_detail_screen.dart';

class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  late Future<List<Job>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = JobsService.browseOpenJobs();
  }

  void _refresh() => setState(() => _jobsFuture = JobsService.browseOpenJobs());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open jobs')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Job>>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load jobs. Pull to retry.'));
            }
            final jobs = snapshot.data ?? [];
            if (jobs.isEmpty) {
              return const Center(child: Text('No open jobs right now. Check back soon.'));
            }
            return ListView.separated(
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final job = jobs[i];
                return ListTile(
                  title: Text(job.title),
                  subtitle: Text(
                    '${job.category} · ${job.location}'
                    '${job.requiredStarLevel != null ? ' · Requires tier ${job.requiredStarLevel}+' : ''}'
                    '${job.budgetMin != null ? ' · GHS ${job.budgetMin}-${job.budgetMax ?? '?'}' : ''}',
                  ),
                  trailing: Text('${job.applicationCount} applicant(s)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProviderJobDetailScreen(jobId: job.id))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
