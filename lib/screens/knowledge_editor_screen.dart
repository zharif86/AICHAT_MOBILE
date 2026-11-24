import 'package:material_ui/material_ui.dart';

import '../models/records.dart';
import '../services/api_exception.dart';
import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';

class KnowledgeEditorScreen extends StatefulWidget {
  const KnowledgeEditorScreen({super.key, this.record});

  final KnowledgeRecord? record;

  @override
  State<KnowledgeEditorScreen> createState() => _KnowledgeEditorScreenState();
}

class _KnowledgeEditorScreenState extends State<KnowledgeEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _body;
  late final TextEditingController _url;
  late final TextEditingController _source;
  late String _kind;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _title = TextEditingController(text: record?.title ?? '');
    _summary = TextEditingController(text: record?.summary ?? '');
    _body = TextEditingController(text: record?.body ?? '');
    _url = TextEditingController(text: record?.url ?? '');
    _source = TextEditingController(text: record?.source ?? '');
    _kind = record?.kind == 'link' ? 'link' : 'text';
    _active = record?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    _url.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Tajuk diperlukan.');
      return;
    }
    if (_kind == 'text' && _body.text.trim().isEmpty) {
      setState(() => _error = 'Teks maklumat diperlukan.');
      return;
    }
    if (_kind == 'link' && !_url.text.trim().startsWith('http')) {
      setState(() => _error = 'Pautan mesti URL yang sah.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      await session.guard(
        () => session.api.saveKnowledge(
          id: widget.record?.id,
          title: title,
          kind: _kind,
          summary: _summary.text,
          body: _body.text,
          url: _url.text,
          source: _source.text,
          isActive: _active,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  Future<void> _delete() async {
    final record = widget.record;
    if (record == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam sumber?'),
        content: const Text('Maklumat ini akan dikeluarkan daripada pangkalan pengetahuan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Padam')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final session = SessionScope.of(context);
      await session.guard(() => session.api.deleteKnowledge(record.id));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showNote(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.record != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Sunting sumber' : 'Sumber baharu')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'text', label: Text('Teks'), icon: Icon(Icons.notes_outlined)),
                    ButtonSegment(value: 'link', label: Text('Pautan'), icon: Icon(Icons.link)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _saving
                      ? null
                      : (value) => setState(() => _kind = value.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Tajuk'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _summary,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Keterangan ringkas'),
                ),
                const SizedBox(height: 12),
                if (_kind == 'text')
                  TextField(
                    controller: _body,
                    minLines: 6,
                    maxLines: 12,
                    decoration: const InputDecoration(labelText: 'Teks maklumat'),
                  )
                else
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Pautan',
                      hintText: 'https://',
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _source,
                  decoration: const InputDecoration(labelText: 'Sumber'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Aktif',
                    style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Hanya sumber aktif digunakan semasa menjawab.',
                    style: TextStyle(fontFamily: 'Manrope', color: Palette.inkSoft),
                  ),
                  value: _active,
                  onChanged: _saving ? null : (value) => setState(() => _active = value),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Palette.danger,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (editing)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      child: const Text('Padam', style: TextStyle(color: Palette.danger)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Menyimpan' : 'Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
