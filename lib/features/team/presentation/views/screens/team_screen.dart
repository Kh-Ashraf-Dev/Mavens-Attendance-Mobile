import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/common.dart';
import '../../../../../core/widgets/load_state.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../view_model/team_cubit.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final TeamCubit cubit = locator();
  String query = '';
  @override
  void initState() {
    super.initState();
    cubit.load();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<TeamCubit, LoadState>(
    bloc: cubit,
    builder: (context, state) {
      final rows = (state.data as List? ?? [])
          .where(
            (r) => r['user']['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      return RefreshIndicator(
        onRefresh: () => cubit.load(),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SectionTitle(
              'Your people',
              'Attendance and annual leave, together.',
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Find a team member',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 20),
            if (state.busy) const Center(child: CircularProgressIndicator()),
            if (state.error != null) Text(state.error!),
            if (!state.busy && state.error == null)
              Text(
                '${rows.length} TEAM MEMBERS',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  letterSpacing: 1.2,
                ),
              ),
            const SizedBox(height: 12),
            if (!state.busy && rows.isEmpty)
              const EmptyPanel(
                'No team members',
                'Your assigned recruiters will appear here.',
              ),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xffedf3fa),
                            foregroundColor: AppTheme.blue,
                            child: Text(
                              row['user']['name'].toString().substring(0, 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row['user']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  row['user']['role'].toString().toLowerCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        row['balance']['configured']
                            ? '${number(row['balance']['available'])} annual days available'
                            : 'Hiring date not configured',
                        style: const TextStyle(
                          color: AppTheme.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Approved: ${number(row['balance']['used'])} · Pending: ${row['balance']['pending']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if ((row['attendance'] as List).isEmpty)
                        const Text(
                          'No attendance recorded',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        )
                      else ...[
                        Text(
                          'Last attendance · ${dateText(row['attendance'][0]['workDate'])}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${timeText(row['attendance'][0]['checkIn'])} – ${timeText(row['attendance'][0]['checkOut'])}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            StatusPill(
                              row['attendance'][0]['late'] ? 'LATE' : 'ON TIME',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      );
    },
  );
}
