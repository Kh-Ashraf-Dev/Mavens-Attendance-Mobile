import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/theme/app_theme.dart';
import 'core/services/locator/service_locator.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/presentation/views/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  configureDependencies();
  String? token;
  try {
    token = await locator<FlutterSecureStorage>().read(key: 'token');
  } catch (_) {
    token = null;
  }
  runApp(MavensApp(signedIn: token != null));
}

class MavensApp extends StatefulWidget {
  final bool signedIn;
  const MavensApp({super.key, this.signedIn = false});
  @override
  State<MavensApp> createState() => _MavensAppState();
}

class _MavensAppState extends State<MavensApp> {
  late bool signedIn = widget.signedIn;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mavens Attendance',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: signedIn
        ? AppShell(onLogout: () => setState(() => signedIn = false))
        : LoginScreen(onLogin: () => setState(() => signedIn = true)),
  );
}
