import 'package:flutter/material.dart';
import '../../../../../core/services/locator/service_locator.dart';
import '../../../../../core/widgets/common.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../domain/use_cases/messaging_actions.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MessagesScreen({super.key, required this.user});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagingActions actions = locator();
  final text = TextEditingController();
  List<dynamic> people = [], messages = [];
  String? recipient, error;
  bool loading = true, sending = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final results = await Future.wait([actions.directory(), actions.list()]);
    if (!mounted) return;
    results[0].fold(
      (f) => error = f.message,
      (v) => people = (v as List)
          .where(
            (p) => p['id'] != widget.user['id'] && p['role'] != 'PERSONNEL',
          )
          .toList(),
    );
    results[1].fold((f) => error = f.message, (v) => messages = v as List);
    if (recipient == null && people.isNotEmpty) recipient = people.first['id'];
    setState(() => loading = false);
    await markRead();
  }

  Future<void> markRead() async {
    for (final m in messages.where(
      (m) =>
          m['recipientId'] == widget.user['id'] &&
          m['senderId'] == recipient &&
          m['readAt'] == null,
    )) {
      await actions.markRead({'id': m['id']});
    }
  }

  Future<void> send() async {
    if (sending || text.text.trim().isEmpty || recipient == null) return;
    setState(() => sending = true);
    final result = await actions.send({
      'recipientId': recipient,
      'body': text.text.trim(),
    });
    if (!mounted) return;
    result.fold((f) => notify(context, f.message), (_) {
      text.clear();
    });
    setState(() => sending = false);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final thread = messages
        .where(
          (m) =>
              (m['senderId'] == recipient &&
                  m['recipientId'] == widget.user['id']) ||
              (m['senderId'] == widget.user['id'] &&
                  m['recipientId'] == recipient),
        )
        .toList();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SectionTitle(
                  'Stay connected',
                  'Questions, updates and a little support.',
                ),
                if (loading) const Center(child: CircularProgressIndicator()),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                if (people.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: recipient,
                    decoration: const InputDecoration(
                      labelText: 'Conversation with',
                      prefixIcon: Icon(Icons.forum_outlined),
                    ),
                    items: people
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text(p['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => recipient = v);
                      markRead();
                    },
                  ),
                const SizedBox(height: 22),
                if (!loading && thread.isEmpty)
                  const EmptyPanel(
                    'Start a conversation',
                    'Message Moataz or your reporting line directly.',
                    icon: Icons.chat_bubble_outline,
                  ),
                for (final m in thread)
                  Align(
                    alignment: m['senderId'] == widget.user['id']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: m['senderId'] == widget.user['id']
                            ? AppTheme.navy
                            : Colors.white,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['body'],
                            style: TextStyle(
                              color: m['senderId'] == widget.user['id']
                                  ? Colors.white
                                  : AppTheme.ink,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${dateText(m['sentAt'])} · ${timeText(m['sentAt'])}${m['senderId'] == widget.user['id'] && m['readAt'] != null ? ' · Read' : ''}',
                            style: TextStyle(
                              fontSize: 9,
                              color: m['senderId'] == widget.user['id']
                                  ? Colors.white60
                                  : AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      hintText: 'Write a message…',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: sending || recipient == null ? null : send,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
