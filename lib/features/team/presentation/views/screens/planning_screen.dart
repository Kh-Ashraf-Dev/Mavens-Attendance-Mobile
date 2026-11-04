import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../../core/services/api/api_client.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/common.dart';

class PlanningScreen extends StatefulWidget {
  final bool isAdmin;
  const PlanningScreen({super.key, required this.isAdmin});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final api = locator<ApiClient>();
  late DateTime week;
  List<dynamic> rows = [];
  final Set<String> selected = {};
  final Set<String> home = {};
  bool busy = false;
  String? error;
  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime now() {
    final n = tz.TZDateTime.now(tz.getLocation('Africa/Cairo'));
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final n = now();
    week = n.subtract(Duration(days: n.weekday % 7));
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    final result = await api.call('/team/planning?weekStart=${iso(week)}');
    if (!mounted) return;
    result.fold(
      (f) => setState(() => error = f.message),
      (v) => setState(() {
        rows = v as List;
        selected.clear();
        home.clear();
      }),
    );
    setState(() => busy = false);
  }

  Future<void> save(String path, Map<String, dynamic> data) async {
    setState(() => busy = true);
    final result = await api.call(path, post: true, data: data);
    if (!mounted) return;
    var success = false;
    result.fold((f) => notify(context, f.message), (_) {
      success = true;
      notify(context, 'Saved successfully');
    });
    setState(() => busy = false);
    if (success) await load();
  }

  Future<void> permission(Map row) async {
    if (week.add(const Duration(days: 6)).isBefore(now())) {
      notify(context, 'Choose the current or a future week.');
      return;
    }
    DateTime day = now().isAfter(week) ? now() : week;
    if (!day.isBefore(week.add(const Duration(days: 7)))) day = week;
    final picked = await showDatePicker(
      context: context,
      initialDate: day.isBefore(now()) ? now() : day,
      firstDate: now().isAfter(week) ? now() : week,
      lastDate: week.add(const Duration(days: 6)),
    );
    if (picked == null || !mounted) return;
    final existing = (row['permissions'] as List)
        .where((p) => p['workDate'] == iso(picked))
        .firstOrNull;
    bool anywhere = existing?['anywhere'] == true;
    bool early = existing?['checkoutFrom'] != null;
    TimeOfDay time = early
        ? TimeOfDay(
            hour: int.parse(existing['checkoutFrom'].toString().split(':')[0]),
            minute: int.parse(
              existing['checkoutFrom'].toString().split(':')[1],
            ),
          )
        : const TimeOfDay(hour: 16, minute: 0);
    final note = TextEditingController(text: existing?['note'] ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text('Attendance permission · ${iso(picked)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(row['user']['name']),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mission: punch from anywhere'),
                  value: anywhere,
                  onChanged: widget.isAdmin
                      ? (v) => refresh(() => anywhere = v)
                      : null,
                ),
                if (!widget.isAdmin)
                  const Text(
                    'Only the admin can change mission location access.',
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow early checkout'),
                  value: early,
                  onChanged: (v) => refresh(() => early = v),
                ),
                if (early)
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: time,
                      );
                      if (t != null) refresh(() => time = t);
                    },
                    child: Text('Checkout from ${time.format(ctx)} · Cairo'),
                  ),
                TextField(
                  controller: note,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                  ),
                ),
                const Text('Turn permissions off and save to revoke them.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final reason = note.text.trim();
    note.dispose();
    if (accepted != true || !mounted) return;
    if (reason.isEmpty) {
      notify(context, 'Enter a reason for the permission.');
      return;
    }
    await save('/team/${row['user']['id']}/permission', {
      'workDate': iso(picked),
      'anywhere': anywhere,
      'checkoutFrom': early
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : null,
      'note': reason,
    });
  }

  @override
  Widget build(BuildContext context) {
    final working = rows.isEmpty
        ? <String>[]
        : List<String>.from(rows.first['workingDays']);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly team planning')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose two home days for each week. Select one person or apply the same days to several team members.',
          ),
          Row(
            children: [
              IconButton(
                onPressed: busy
                    ? null
                    : () {
                        week = week.subtract(const Duration(days: 7));
                        load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${iso(week)} — ${iso(week.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: busy
                    ? null
                    : () {
                        week = week.add(const Duration(days: 7));
                        load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            TextButton(onPressed: load, child: Text('$error · Retry')),
          if (!busy && rows.isEmpty && error == null)
            const Text('No assigned team members.'),
          Wrap(
            spacing: 8,
            children: working
                .map(
                  (d) => FilterChip(
                    label: Text(d.substring(0, 3)),
                    selected: home.contains(d),
                    onSelected: busy
                        ? null
                        : (v) => setState(() {
                            v ? home.add(d) : home.remove(d);
                          }),
                  ),
                )
                .toList(),
          ),
          Text('${home.length} / 2 home days selected'),
          if (rows.isNotEmpty)
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      selected.addAll(
                        rows.map((r) => r['user']['id'] as String),
                      );
                    }),
              child: const Text('Select entire team'),
            ),
          for (final row in rows)
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: selected.contains(row['user']['id']),
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            final id = row['user']['id'] as String;
                            if (v == true) {
                              selected.add(id);
                              if (selected.length == 1) {
                                home.clear();
                                home.addAll(List<String>.from(row['homeDays']));
                              }
                            } else {
                              selected.remove(id);
                            }
                          }),
                    title: Text(row['user']['name']),
                    subtitle: Text(
                      '${(row['homeDays'] as List).join(', ')} · ${row['weeklyOverride'] == true ? 'Saved for this week' : 'Default schedule'}',
                    ),
                  ),
                  for (final p in row['permissions'])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        '${p['workDate']} · ${p['anywhere'] == true ? 'Mission anywhere · ' : ''}Checkout ${p['checkoutFrom'] ?? '18:00'} · ${p['note']}',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: busy ? null : () => permission(row),
                    icon: const Icon(Icons.tune),
                    label: const Text('Attendance permission'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy || selected.isEmpty || home.length != 2
                ? null
                : () => save('/team/schedule', {
                    'employeeIds': selected.toList(),
                    'weekStart': iso(week),
                    'homeDays': home.toList(),
                  }),
            child: Text('Save week for ${selected.length} people'),
          ),
          TextButton(
            onPressed: busy || selected.isEmpty
                ? null
                : () => save('/team/schedule', {
                    'employeeIds': selected.toList(),
                    'weekStart': iso(week),
                    'homeDays': null,
                  }),
            child: const Text('Restore default schedule for selected people'),
          ),
        ],
      ),
    );
  }
}
