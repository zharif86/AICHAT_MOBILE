import 'package:material_ui/material_ui.dart';

import '../models/records.dart';
import '../services/api_exception.dart';
import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';
import '../widgets/message_text.dart';
import 'thread_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  static const _filters = <(String, String?)>[
    ('Semua', null),
    ('Dibuka', 'open'),
    ('Dikosongkan', 'cleared'),
  ];

  String? _status;
  bool _loading = true;
  bool _starting = false;
  String? _error;
  List<ConversationSummary> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      final page = await session.guard(
        () => session.api.conversations(status: _status),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final session = SessionScope.of(context);
      final created = await session.guard(() => session.api.createConversation());
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ThreadScreen(id: created.id)),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        showNote(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _open(ConversationSummary item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ThreadScreen(id: item.id)),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('Perbualan'),
                        SizedBox(height: 6),
                        Text(
                          'Sembang',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _starting ? null : _start,
                    icon: _starting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: const Text('Baharu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.sageDeep,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return ChoiceChip(
                    label: Text(filter.$1),
                    selected: _status == filter.$2,
                    onSelected: (_) {
                      setState(() => _status = filter.$2);
                      _load();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return QuietError(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const _EmptyInbox();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _ConversationCard(item: item, onTap: () => _open(item));
        },
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.item, required this.onTap});

  final ConversationSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.paper,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(label: item.statusLabel, open: item.isOpen),
                    const Spacer(),
                    Text(
                      formatWhen(item.updatedAt),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Palette.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.preview == null ? 'Perbualan baharu' : plainMessage(item.preview!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.messageCount} mesej',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    color: Palette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 64),
            SizedBox(height: 18),
            Text(
              'Belum ada perbualan',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mulakan pertanyaan baharu. Rekod disimpan untuk rujukan pegawai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: Palette.inkSoft,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
