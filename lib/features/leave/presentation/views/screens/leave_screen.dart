import 'package:flutter/material.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/common.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../domain/use_cases/leave_actions.dart';

class LeaveScreen extends StatefulWidget {
  final Map<String, dynamic> user, balance;
  const LeaveScreen({super.key, required this.user, required this.balance});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveActions actions = locator();
  List<dynamic>? rows;
  String? error;
  Map<String, dynamic>? currentBalance;
  bool inbox = false, busy = false;
  String type = 'REGULAR';
  DateTime? start, end;
  final reason = TextEditingController();
  bool get hr => ['SUPERVISOR', 'ADMIN'].contains(widget.user['role']);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final results = await Future.wait([
      inbox ? actions.inbox() : actions.list(),
      actions.balance(),
    ]);
    final result = results[0];
    if (!mounted) return;
    results[1].fold(
      (_) {},
      (v) => currentBalance = Map<String, dynamic>.from(v),
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() => error = f.message),
      (v) => setState(() {
        rows = v as List;
        error = null;
      }),
    );
  }

  Future<void> chooseDate(bool first, StateSetter update) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: (first ? start : end) ?? start ?? now,
      firstDate: first ? now : start ?? now,
      lastDate: now.add(const Duration(days: 364)),
    );
    if (picked != null) {
      update(() {
        if (first) {
          start = picked;
          if (end != null && end!.isBefore(picked)) {
            end = picked;
          }
        } else {
          end = picked;
        }
      });
    }
  }

  Future<void> create() async {
    final form = GlobalKey<FormState>();
    bool submitting = false;
    type = 'REGULAR';
    start = null;
    end = null;
    reason.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            24,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request time off',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your manager will review your request. Working days only.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Leave type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'REGULAR',
                        child: Text('Regular annual leave'),
                      ),
                      DropdownMenuItem(
                        value: 'SICK',
                        child: Text('Sick leave'),
                      ),
                      DropdownMenuItem(
                        value: 'UNPAID',
                        child: Text('Unpaid leave'),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) => update(() => type = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: submitting
                              ? null
                              : () => chooseDate(true, update),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            start == null
                                ? 'Start date'
                                : dateText(start!.toIso8601String()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: submitting
                              ? null
                              : () => chooseDate(false, update),
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            end == null
                                ? 'End date'
                                : dateText(end!.toIso8601String()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reason,
                    maxLines: 3,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Reason for leave',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please add a reason'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              if (start == null || end == null) {
                                notify(
                                  context,
                                  'Select your start and end dates.',
                                );
                                return;
                              }
                              update(() => submitting = true);
                              final result = await actions.request({
                                'type': type,
                                'startDate': start!.toIso8601String().substring(
                                  0,
                                  10,
                                ),
                                'endDate': end!.toIso8601String().substring(
                                  0,
                                  10,
                                ),
                                'reason': reason.text.trim(),
                              });
                              if (!context.mounted) return;
                              result.fold(
                                (f) {
                                  notify(context, f.message);
                                  update(() => submitting = false);
                                },
                                (_) {
                                  Navigator.pop(context);
                                  notify(
                                    this.context,
                                    'Leave request sent to your manager.',
                                  );
                                  load();
                                },
                              );
                            },
                      child: Text(submitting ? 'Sending…' : 'Send request'),
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

  Future<void> review(dynamic row, bool approve) async {
    final note = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve leave?' : 'Reject leave?'),
        content: TextField(
          controller: note,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Review note (required)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (note.text.trim().isNotEmpty) {
                Navigator.pop(context, note.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    note.dispose();
    if (text == null) return;
    setState(() => busy = true);
    final result = await actions.review({
      'id': row['id'],
      'approve': approve,
      'note': text,
    });
    if (!mounted) return;
    result.fold(
      (f) => notify(context, f.message),
      (_) => notify(context, 'Request updated.'),
    );
    setState(() => busy = false);
    load();
  }

  @override
  Widget build(BuildContext context) {
    final b = currentBalance ?? widget.balance;
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SectionTitle(
            'Time to recharge',
            'Manage your annual leave and requests.',
          ),
          Panel(
            color: AppTheme.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AVAILABLE ANNUAL LEAVE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  b['configured']
                      ? '${number(b['available'])} days'
                      : 'Hiring date needed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Accrued ${number(b['accrued'])}  ·  Approved ${number(b['used'])}\nPending ${b['pending']} days',
                  style: const TextStyle(color: Colors.white70, height: 1.8),
                ),
                const SizedBox(height: 14),
                const Text(
                  '1.75 days per 30 calendar days since hiring.\nApproved future leave is reserved. Sick and unpaid leave do not reduce this balance.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : create,
            icon: const Icon(Icons.add),
            label: const Text('Request leave'),
          ),
          const SizedBox(height: 24),
          if (hr)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('My requests')),
                ButtonSegment(value: true, label: Text('Team requests')),
              ],
              selected: {inbox},
              onSelectionChanged: (v) {
                setState(() {
                  inbox = v.first;
                  rows = null;
                });
                load();
              },
            ),
          const SizedBox(height: 16),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (rows == null && error == null)
            const Center(child: CircularProgressIndicator()),
          if (rows != null && rows!.isEmpty)
            const EmptyPanel(
              'No requests yet',
              'Your leave requests and manager decisions will appear here.',
              icon: Icons.beach_access_outlined,
            ),
          for (final row in rows ?? [])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${row['type']} LEAVE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        StatusPill(row['status']),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (inbox)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${row['employeeName'] ?? 'Team member'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    Text(
                      '${dateText(row['startDate'])} – ${dateText(row['endDate'])}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${row['days']} working day(s)',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(row['reason']),
                    if (row['reviewNote'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Manager: ${row['reviewNote']}',
                          style: const TextStyle(color: AppTheme.blue),
                        ),
                      ),
                    if (row['status'] == 'PENDING' && !inbox)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                final result = await actions.cancel({
                                  'id': row['id'],
                                });
                                if (!mounted) return;
                                result.fold(
                                  (f) => notify(context, f.message),
                                  (_) => notify(context, 'Request cancelled.'),
                                );
                                setState(() => busy = false);
                                load();
                              },
                        child: const Text('Cancel request'),
                      ),
                    if (inbox &&
                        row['status'] == 'PENDING' &&
                        row['employeeId'] != widget.user['id'])
                      Row(
                        children: [
                          TextButton(
                            onPressed: busy ? null : () => review(row, false),
                            child: const Text('Reject'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: busy ? null : () => review(row, true),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
