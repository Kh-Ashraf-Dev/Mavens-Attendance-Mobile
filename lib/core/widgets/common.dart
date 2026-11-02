import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_theme.dart';

String number(dynamic n) => n is num ? n.toStringAsFixed(2) : '—';
String dateText(dynamic v) => v == null
    ? '—'
    : DateFormat('dd MMM yyyy').format(
        v.toString().length == 10
            ? DateTime.parse(v.toString())
            : tz.TZDateTime.from(
                DateTime.parse(v.toString()),
                tz.getLocation('Africa/Cairo'),
              ),
      );
String timeText(dynamic v) => v == null
    ? '—'
    : DateFormat('h:mm a').format(
        tz.TZDateTime.from(
          DateTime.parse(v.toString()),
          tz.getLocation('Africa/Cairo'),
        ),
      );

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  const Panel({super.key, required this.child, this.color});
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const SectionTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppTheme.muted)),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  final String label;
  final bool onDark;
  const StatusPill(this.label, {super.key, this.onDark = false});
  @override
  Widget build(BuildContext context) {
    final good = ['APPROVED', 'ON TIME', 'HOME', 'ACTIVE'].contains(label);
    final bad = ['REJECTED', 'LATE', 'BLOCKED'].contains(label);
    final color = onDark
        ? Colors.white
        : good
        ? const Color(0xff16816c)
        : bad
        ? const Color(0xffb8423b)
        : AppTheme.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void notify(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class EmptyPanel extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const EmptyPanel(
    this.title,
    this.subtitle, {
    super.key,
    this.icon = Icons.inbox_outlined,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.blue),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
