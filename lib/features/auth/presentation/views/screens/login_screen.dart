import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/load_state.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../view_model/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  late final AuthCubit cubit = locator();
  bool obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    cubit.close();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    try {
      await cubit.login({
        'email': email.text.trim(),
        'password': password.text,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secure storage is unavailable on this device.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BlocConsumer<AuthCubit, LoadState>(
              bloc: cubit,
              listener: (context, state) async {
                if (state.data != null) {
                  try {
                    await locator<FlutterSecureStorage>().write(
                      key: 'token',
                      value: state.data['token'],
                    );
                    if (mounted) {
                      widget.onLogin();
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to save your session securely. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              builder: (context, state) => Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/mavens-logo.png', width: 190),
                    const SizedBox(height: 48),
                    const Text(
                      'YOUR WORKDAY, CONNECTED',
                      style: TextStyle(
                        color: AppTheme.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to\nMavens Attendance',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your attendance, time off and team.\nAll in one place.',
                      style: TextStyle(color: AppTheme.muted, height: 1.7),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: email,
                      autofillHints: const [AutofillHints.username],
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Work email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter your work email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      autofillHints: const [AutofillHints.password],
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your password' : null,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 16),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.busy ? null : submit,
                        child: state.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign in  →'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffedf3fa),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: AppTheme.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Stay connected wherever you work.\nSign in with your work email on your phone or another device.',
                              style: TextStyle(fontSize: 12, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
