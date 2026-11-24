import 'package:material_ui/material_ui.dart';

import '../models/records.dart';
import '../services/api_exception.dart';
import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';
import 'knowledge_editor_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final _query = TextEditingController();
  bool _loading = true;
  String? _error;
  List<KnowledgeRecord> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      final first = await session.guard(() => session.api.knowledge());
      final items = [...first.items];
      var page = first;
      while (page.hasMore && mounted) {
        page = await session.guard(() => session.api.knowledge(page: page.currentPage + 1));
        items.addAll(page.items);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
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

  Future<void> _open([KnowledgeRecord? record]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => KnowledgeEditorScreen(record: record)),
    );
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();
    final visible = _items.where((item) {
      if (query.isEmpty) {
        return true;
      }
      final haystack = '${item.title} ${item.summary ?? ''} ${item.source ?? ''}'.toLowerCase();
      return haystack.contains(query);
    }).toList();

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
                        Eyebrow('Pangkalan'),
                        SizedBox(height: 6),
                        Text(
                          'Sumber',
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
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari tajuk atau sumber',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(child: _body(visible)),
          ],
        ),
      ),
    );
  }

  Widget _body(List<KnowledgeRecord> visible) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return QuietError(message: _error!, onRetry: _load);
    }
    if (visible.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Tiada sumber yang sepadan. Tambah teks atau pautan rasmi untuk dijadikan rujukan jawapan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Manrope', color: Palette.inkSoft, height: 1.45),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = visible[index];
          return Material(
            color: Palette.paper,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _open(item),
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
                          StatusPill(label: item.kindLabel, open: item.kind == 'text'),
                          const SizedBox(width: 8),
                          StatusPill(label: item.status, open: item.isActive),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if ((item.summary ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: Palette.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if ((item.source ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.source!,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Palette.sage,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
