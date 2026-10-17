import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_provider.dart';
import 'jobs/my_jobs_screen.dart';
import 'jobs/browse_jobs_screen.dart';
import 'providers/provider_directory_screen.dart';
import 'applications/my_applications_screen.dart';

/// One shell for both roles: a customer sees "My jobs" + "Providers", a
/// provider sees "Open jobs" + "Applications". Same profile/logout tab either way.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isProvider = authState.isProvider;

    final pages = <Widget>[
      isProvider ? const BrowseJobsScreen() : const MyJobsScreen(),
      isProvider ? const MyApplicationsScreen() : const ProviderDirectoryScreen(),
      _ProfileTab(name: user?.fullName ?? '', role: user?.role ?? ''),
    ];

    final destinations = isProvider
        ? const [
            NavigationDestination(icon: Icon(Icons.search), label: 'Open jobs'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Applications'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.work_outline), label: 'My jobs'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Providers'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final String name;
  final String role;
  const _ProfileTab({required this.name, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (role.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(role == 'PROVIDER' ? 'Provider account' : 'Customer account',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
