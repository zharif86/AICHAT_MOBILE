import 'package:material_ui/material_ui.dart';

import '../models/records.dart';
import '../services/api_exception.dart';
import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';
import '../widgets/message_text.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key, required this.id});

  final int id;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ConversationDetail? _conversation;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _conversation == null;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      final detail = await session.guard(() => session.api.conversation(widget.id));
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = detail;
        _loading = false;
      });
      _jumpToEnd();
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

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    final conversation = _conversation;
    if (text.isEmpty || _sending || conversation == null || !conversation.isOpen) {
      return;
    }
    if (text.length > 2000) {
      showNote(context, 'Mesej tidak boleh melebihi 2000 aksara.');
      return;
    }
    setState(() {
      _sending = true;
      _pending = text;
      _error = null;
    });
    _input.clear();
    _jumpToEnd();
    try {
      final session = SessionScope.of(context);
      final result = await session.guard(() => session.api.sendMessage(widget.id, text));
      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = ConversationDetail(
          id: conversation.id,
          status: conversation.status,
          statusLabel: conversation.statusLabel,
          messages: [...conversation.messages, result.user, result.assistant],
        );
        _pending = null;
        _sending = false;
      });
      _jumpToEnd();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pending = null;
        _sending = false;
        _input.text = text;
        _error = error.message;
      });
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kosongkan perbualan?',
          style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Perbualan ditutup. Rekod mesej kekal untuk rujukan, dan mesej baharu tidak lagi diterima.',
          style: TextStyle(fontFamily: 'Manrope', height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kosongkan')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final session = SessionScope.of(context);
      final detail = await session.guard(() => session.api.clearConversation(widget.id));
      if (!mounted) {
        return;
      }
      setState(() => _conversation = detail);
    } on ApiException catch (error) {
      if (mounted) {
        showNote(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final conversation = _conversation;
    final name = session.agent?.name ?? 'JapenAi';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name),
            if (conversation != null)
              Text(
                conversation.statusLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Palette.inkSoft,
                ),
              ),
          ],
        ),
        actions: [
          if (conversation != null && conversation.isOpen)
            IconButton(
              tooltip: 'Kosongkan',
              onPressed: _sending ? null : _clear,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _thread(name)),
          if (_error != null && conversation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: Palette.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (conversation != null && conversation.isOpen) _composer() else if (conversation != null) _closedNote(),
        ],
      ),
    );
  }

  Widget _thread(String name) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_conversation == null) {
      return QuietError(message: _error ?? 'Perbualan tidak dijumpai.', onRetry: _load);
    }
    final welcome = SessionScope.of(context).agent?.welcomeMessage ?? '';
    final questions = SessionScope.of(context).agent?.suggestedQuestions ?? const <String>[];
    final messages = _conversation!.messages;
    final showWelcome = messages.isEmpty && _pending == null;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (showWelcome) _Welcome(name: name, message: welcome, questions: questions, onAsk: _send),
        for (final message in messages) _Bubble(message: message, name: name),
        if (_pending != null)
          _Bubble(
            name: name,
            message: ChatMessage(
              id: -1,
              role: 'user',
              roleLabel: 'Pengguna',
              content: _pending!,
              status: 'completed',
              createdAt: DateTime.now(),
            ),
          ),
        if (_sending) const _Typing(),
      ],
    );
  }

  Widget _composer() {
    final length = _input.text.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.line),
            boxShadow: Palette.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pertanyaan rasmi',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Palette.sageDeep),
                        onPressed: _sending || _input.text.trim().isEmpty ? null : () => _send(),
                        icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (length > 1600)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 6),
                      child: Text(
                        '$length/2000',
                        style: const TextStyle(fontSize: 11, color: Palette.inkSoft),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closedNote() {
    return const SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text(
          'Perbualan ini telah dikosongkan. Buka perbualan baharu untuk bertanya semula.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Manrope', color: Palette.inkSoft, height: 1.4),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.name,
    required this.message,
    required this.questions,
    required this.onAsk,
  });

  final String name;
  final String message;
  final List<String> questions;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15.5,
              height: 1.5,
              color: Palette.inkSoft,
            ),
          ),
          if (questions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final question in questions)
                  ActionChip(
                    label: Text(question),
                    onPressed: () => onAsk(question),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.name});

  final ChatMessage message;
  final String name;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    final failed = message.failed;
    final color = mine
        ? Palette.sageDeep
        : failed
        ? Palette.dangerMist
        : Palette.paper;
    final textColor = mine
        ? Colors.white
        : failed
        ? Palette.danger
        : Palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.84),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkSoft,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 6),
                    bottomRight: Radius.circular(mine ? 6 : 18),
                  ),
                  border: mine ? null : Border.all(color: failed ? Palette.dangerMist : Palette.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: MessageText(
                    text: message.content,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      height: 1.45,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              if (message.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    formatWhen(message.createdAt),
                    style: const TextStyle(fontSize: 11, color: Palette.inkSoft),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Menyusun jawapan',
            style: TextStyle(
              fontFamily: 'Manrope',
              color: Palette.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
