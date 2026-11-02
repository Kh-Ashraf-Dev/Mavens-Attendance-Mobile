import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/widgets/common.dart';
import '../../../../../core/widgets/load_state.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../view_model/attendance_cubit.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final AttendanceCubit cubit = locator();
  bool punching = false;
  @override
  void initState() {
    super.initState();
    cubit.overview();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  Future<void> punch(Map data, bool checkout) async {
    setState(() => punching = true);
    try {
      final gps = data['mode'] == 'SITE'
          ? await locator<LocationService>().capture()
          : <String, dynamic>{};
      final result = checkout
          ? await cubit.actions.checkOut(gps)
          : await cubit.actions.checkIn(gps);
      if (!mounted) return;
      result.fold(
        (f) => notify(context, f.message),
        (_) => notify(
          context,
          checkout
              ? 'Checked out. Have a good evening!'
              : 'Check-in recorded. Have a great day!',
        ),
      );
      await cubit.overview();
    } catch (e) {
      if (mounted) {
        notify(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => punching = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AttendanceCubit, LoadState>(
    bloc: cubit,
    builder: (context, state) {
      if (state.busy) return const Center(child: CircularProgressIndicator());
      if (state.error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => cubit.overview(),
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }
      if (state.data == null) return const SizedBox();
      final d = Map<String, dynamic>.from(state.data);
      final b = d['balance'];
      final history = d['attendance'] as List;
      final today = history
          .where((a) => a['workDate'] == d['today'])
          .firstOrNull;
      final checked = today != null;
      final complete = checked && today['checkOut'] != null;
      final mode = d['mode'];
      final user = d['user'];
      return RefreshIndicator(
        onRefresh: () => cubit.overview(),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            SectionTitle(
              'Hello, ${user['name'].toString().split(' ').first}',
              'Here’s your workday at a glance.',
            ),
            Panel(
              color: AppTheme.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateText(d['today']),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      StatusPill(mode, onDark: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    complete
                        ? 'You’re all done'
                        : checked
                        ? 'You’re checked in'
                        : mode == 'OFF'
                        ? 'Enjoy your day off'
                        : mode == 'UNCONFIGURED'
                        ? 'Schedule not set'
                        : 'Ready for your day?',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode == 'UNCONFIGURED'
                        ? 'Your admin will configure your workweek.'
                        : mode == 'SITE'
                        ? 'On site · Office location required'
                        : mode == 'HOME'
                        ? 'Work from home · Stay connected'
                        : 'Your next workday will appear here.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: _Shift('START', '10:00 AM')),
                      Expanded(child: _Shift('END', '6:00 PM')),
                      Expanded(child: _Shift('GRACE', '30 min')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.navy,
                      ),
                      onPressed:
                          punching ||
                              complete ||
                              mode == 'OFF' ||
                              mode == 'UNCONFIGURED'
                          ? null
                          : () => punch(d, checked),
                      icon: punching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(checked ? Icons.logout : Icons.fingerprint),
                      label: Text(
                        punching
                            ? 'Verifying attendance…'
                            : complete
                            ? 'Shift completed'
                            : checked
                            ? 'Check out'
                            : 'Check in',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.login, color: AppTheme.blue),
                        const SizedBox(height: 10),
                        Text(
                          timeText(today?['checkIn']),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Check-in',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.logout, color: AppTheme.blue),
                        const SizedBox(height: 10),
                        Text(
                          timeText(today?['checkOut']),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Check-out',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (user['role'] != 'PERSONNEL')
              Panel(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffedf3fa),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.beach_access_outlined,
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your annual leave',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            b['configured']
                                ? '${number(b['available'])} days available'
                                : 'Ask Moataz to configure your hiring date',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 26),
            const SectionTitle(
              'Your weekly rhythm',
              '3 days on site · 2 days from home',
            ),
            if (d['scheduleConfigured'] == true)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in d['week'] as List)
                    Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: day['mode'] == 'SITE'
                            ? const Color(0xffedf3fa)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffe1e8f0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            day['day'].toString().substring(0, 3),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Icon(
                            day['mode'] == 'SITE'
                                ? Icons.apartment_outlined
                                : Icons.home_work_outlined,
                            color: AppTheme.blue,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day['mode'] == 'SITE' ? 'On site' : 'Home',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else
              const EmptyPanel(
                'Waiting for your schedule',
                'Your admin will choose the working days and home days.',
                icon: Icons.date_range_outlined,
              ),
            const SizedBox(height: 26),
            const SectionTitle(
              'Recent attendance',
              'Your last 90 attendance records',
            ),
            if (history.isEmpty)
              const EmptyPanel(
                'A fresh start',
                'Your attendance history appears after your first check-in.',
                icon: Icons.access_time,
              ),
            for (final a in history.take(15))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateText(a['workDate']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusPill(a['late'] ? 'LATE' : 'ON TIME'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${a['mode'] == 'SITE' ? 'Office' : 'Home'} · ${timeText(a['checkIn'])} – ${timeText(a['checkOut'])}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (a['late'])
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${a['lateMinutes']} minutes after shift start',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xffb8423b),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'All attendance is recorded in Cairo time. Pull down to refresh.',
              style: TextStyle(fontSize: 11, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class _Shift extends StatelessWidget {
  final String label, value;
  const _Shift(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ],
  );
}
