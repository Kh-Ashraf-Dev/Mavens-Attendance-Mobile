import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../../core/services/api/api_client.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/common.dart';
import '../../../../../config/theme/app_theme.dart';

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

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _order = [
    'SUNDAY',
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
  ];

  String short(String day) => day[0] + day.substring(1, 3).toLowerCase();

  DateTime dayDate(String day) => week.add(Duration(days: _order.indexOf(day)));

  String weekLabel() {
    final end = week.add(const Duration(days: 6));
    if (week.month == end.month) {
      return '${week.day}–${end.day} ${_months[end.month - 1]} ${end.year}';
    }
    return '${week.day} ${_months[week.month - 1]} – ${end.day} ${_months[end.month - 1]} ${end.year}';
  }

  String shortWeekLabel() {
    final end = week.add(const Duration(days: 6));
    return week.month == end.month
        ? '${week.day}–${end.day} ${_months[end.month - 1]}'
        : '${week.day} ${_months[week.month - 1]} – ${end.day} ${_months[end.month - 1]}';
  }

  void shiftWeek(int days) {
    week = week.add(Duration(days: days));
    load();
  }

  Widget step(int number, String title, String subtitle, Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xffe4eefa),
                foregroundColor: AppTheme.blue,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.navy,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  Widget dayTile(String d) {
    final chosen = home.contains(d);
    final full = !chosen && home.length >= 2;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: chosen ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: busy || full
                ? null
                : () => setState(() => chosen ? home.remove(d) : home.add(d)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: chosen ? AppTheme.navy : const Color(0xffd5dce6),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    short(d),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: chosen
                          ? Colors.white
                          : full
                          ? AppTheme.muted
                          : AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chosen ? '${dayDate(d).day} ✓' : '${dayDate(d).day}',
                    style: TextStyle(
                      fontSize: 13,
                      color: chosen ? Colors.white : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final working = rows.isEmpty
        ? <String>[]
        : (List<String>.from(rows.first['workingDays'])
            ..sort((a, b) => _order.indexOf(a).compareTo(_order.indexOf(b))));
    final allSelected = rows.isNotEmpty && selected.length == rows.length;
    final homeSorted = home.toList()
      ..sort((a, b) => _order.indexOf(a).compareTo(_order.indexOf(b)));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan team week',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: busy ? null : () => shiftWeek(-7),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffd5dce6)),
                  ),
                  child: Text(
                    weekLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: busy ? null : () => shiftWeek(7),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            TextButton(onPressed: load, child: Text('$error · Retry')),
          if (!busy && rows.isEmpty && error == null)
            const EmptyPanel(
              'No assigned team members',
              'Team members assigned to you will appear here.',
            ),
          if (rows.isNotEmpty) ...[
            step(
              1,
              'Select team members',
              'Apply the same days to selected people.',
              Column(
                children: [
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: allSelected,
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            if (v == true) {
                              selected.addAll(
                                rows.map((r) => r['user']['id'] as String),
                              );
                              if (home.isEmpty) {
                                home.addAll(
                                  List<String>.from(rows.first['homeDays']),
                                );
                              }
                            } else {
                              selected.clear();
                            }
                          }),
                    title: Text(
                      'Select all (${rows.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  for (final row in rows) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selected.contains(row['user']['id']),
                            onChanged: busy
                                ? null
                                : (v) => setState(() {
                                    final id = row['user']['id'] as String;
                                    if (v == true) {
                                      selected.add(id);
                                      if (selected.length == 1) {
                                        home
                                          ..clear()
                                          ..addAll(
                                            List<String>.from(row['homeDays']),
                                          );
                                      }
                                    } else {
                                      selected.remove(id);
                                    }
                                  }),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xffe4eefa),
                            foregroundColor: AppTheme.blue,
                            child: Text(
                              row['user']['name'].toString().substring(0, 1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row['user']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.navy,
                                  ),
                                ),
                                Text(
                                  'Current: ${(row['homeDays'] as List).map((d) => short(d.toString())).join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted,
                                  ),
                                ),
                                for (final p in row['permissions'])
                                  Text(
                                    '${p['workDate']} · ${p['anywhere'] == true ? 'Mission · ' : ''}Out ${p['checkoutFrom'] ?? '18:00'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xffe1e7ef),
                          ),
                          InkWell(
                            onTap: busy ? null : () => permission(row),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: AppTheme.blue,
                                    size: 22,
                                  ),
                                  Text(
                                    'Permissions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            step(
              2,
              'Choose work-from-home days',
              'Choose 2 days for this week.',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [for (final d in working) dayTile(d)]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        home.length == 2
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: home.length == 2
                            ? AppTheme.blue
                            : AppTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${home.length} of 2 days selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: home.length == 2
                              ? AppTheme.blue
                              : AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      'Other working days will be in the office.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ),
                ],
              ),
            ),
            step(
              3,
              'Review',
              '',
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffe8f1fb),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: AppTheme.navy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.isEmpty
                                ? 'No one selected yet'
                                : '${selected.length} ${selected.length == 1 ? 'person' : 'people'} · ${homeSorted.length == 2 ? '${short(homeSorted[0])} & ${short(homeSorted[1])} at home' : 'choose 2 home days'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Applies to ${shortWeekLabel()} only.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: rows.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xffe6ebf2))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: busy || selected.isEmpty || home.length != 2
                            ? null
                            : () => save('/team/schedule', {
                                'employeeIds': selected.toList(),
                                'weekStart': iso(week),
                                'homeDays': home.toList(),
                              }),
                        child: Text(
                          'Save schedule for ${selected.length} ${selected.length == 1 ? 'person' : 'people'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: busy || selected.isEmpty
                          ? null
                          : () => save('/team/schedule', {
                              'employeeIds': selected.toList(),
                              'weekStart': iso(week),
                              'homeDays': null,
                            }),
                      child: const Text(
                        'Restore default schedule',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
