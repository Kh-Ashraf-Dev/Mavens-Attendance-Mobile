import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/locator/service_locator.dart';
import '../../features/attendance/domain/use_cases/attendance_actions.dart';
import '../../features/auth/domain/use_cases/auth_actions.dart';
import '../../features/attendance/presentation/views/screens/today_screen.dart';
import '../../features/leave/presentation/views/screens/leave_screen.dart';
import '../../features/team/presentation/views/screens/team_screen.dart';
import '../../features/messaging/presentation/views/screens/messages_screen.dart';
import '../../config/theme/app_theme.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Map<String, dynamic>? data;
  String? error;
  int index = 0, revision = 0;
  bool switching = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await locator<AttendanceActions>().overview();
    if (!mounted) return;
    result.fold(
      (f) {
        if (f.status == 401 || f.status == 423) {
          logout(remote: false);
          return;
        }
        setState(() => error = f.message);
      },
      (v) => setState(() {
        data = Map<String, dynamic>.from(v);
        error = null;
      }),
    );
  }

  Future<void> logout({bool remote = true}) async {
    if (remote) await locator<AuthActions>().logout();
    await locator<FlutterSecureStorage>().delete(key: 'token');
    widget.onLogout();
  }

  Future<void> change(int v) async {
    if (switching) return;
    setState(() => switching = true);
    await load();
    if (!mounted) return;
    setState(() {
      index = v;
      revision++;
      switching = false;
    });
  }

  Future<void> profile() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data!['user']['name'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(data!['user']['email']),
            Text(
              data!['user']['role'],
              style: const TextStyle(color: AppTheme.blue),
            ),
            const SizedBox(height: 24),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Access your account across devices'),
              subtitle: Text(
                'You can stay signed in on more than one device. Signing out here ends only this session.',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Scaffold(
        body: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    TextButton(onPressed: load, child: const Text('Try again')),
                  ],
                ),
        ),
      );
    }
    final user = Map<String, dynamic>.from(data!['user']);
    final hasTeam = ['SUPERVISOR', 'ADMIN'].contains(user['role']);
    final personnel = user['role'] == 'PERSONNEL';
    if (personnel) index = 0;
    final tabs = [
      const NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Today',
      ),
      if (!personnel)
        const NavigationDestination(
          icon: Icon(Icons.beach_access_outlined),
          selectedIcon: Icon(Icons.beach_access),
          label: 'Leave',
        ),
      if (hasTeam)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Team',
        ),
      if (!personnel)
        const NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: 'Messages',
        ),
    ];
    final Widget page = index == 0
        ? const TodayScreen()
        : index == 1
        ? LeaveScreen(
            user: user,
            balance: Map<String, dynamic>.from(data!['balance']),
          )
        : hasTeam && index == 2
        ? TeamScreen(isAdmin: user['role'] == 'ADMIN')
        : MessagesScreen(user: user);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/mavens-logo.png',
          height: 34,
          width: 130,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'My account',
            onPressed: profile,
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xffe2eef9),
              child: Text(
                user['name'].toString().substring(0, 1),
                style: const TextStyle(fontSize: 14, color: AppTheme.blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: switching
                ? const Center(child: CircularProgressIndicator())
                : KeyedSubtree(key: ValueKey('$index-$revision'), child: page),
          ),
        ),
      ),
      bottomNavigationBar: personnel
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: change,
              destinations: tabs,
            ),
    );
  }
}
