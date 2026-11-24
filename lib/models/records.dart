DateTime? parseApiDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}

String formatWhen(DateTime? time) {
  if (time == null) {
    return '';
  }
  const months = [
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ogos',
    'Sep',
    'Okt',
    'Nov',
    'Dis',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final clock =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (day == today) {
    return clock;
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Semalam';
  }
  return '${time.day} ${months[time.month - 1]}';
}

class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.name,
    required this.welcomeMessage,
    required this.suggestedQuestions,
    required this.isActive,
  });

  final int id;
  final String name;
  final String welcomeMessage;
  final List<String> suggestedQuestions;
  final bool isActive;

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    final questions = <String>[];
    final raw = json['suggested_questions'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) {
          questions.add(item.trim());
        }
      }
    }
    return AgentProfile(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'JapenAi',
      welcomeMessage: (json['welcome_message'] as String?) ?? '',
      suggestedQuestions: questions,
      isActive: json['is_active'] == true,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.roleLabel,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String role;
  final String roleLabel;
  final String content;
  final String status;
  final DateTime? createdAt;

  bool get fromUser => role == 'user';
  bool get failed => status == 'failed';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      role: (json['role'] as String?) ?? 'assistant',
      roleLabel: (json['role_label'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'completed',
      createdAt: parseApiDate(json['created_at']),
    );
  }
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.preview,
    required this.messageCount,
    required this.updatedAt,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String? preview;
  final int messageCount;
  final DateTime? updatedAt;

  bool get isOpen => status == 'open';

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as int,
      status: (json['status'] as String?) ?? 'open',
      statusLabel: (json['status_label'] as String?) ?? '',
      preview: json['preview'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      updatedAt: parseApiDate(json['updated_at']),
    );
  }
}

class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.messages,
  });

  final int id;
  final String status;
  final String statusLabel;
  final List<ChatMessage> messages;

  bool get isOpen => status == 'open';

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    final messages = <ChatMessage>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          messages.add(ChatMessage.fromJson(item));
        } else if (item is Map) {
          messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ConversationDetail(
      id: json['id'] as int,
      status: (json['status'] as String?) ?? 'open',
      statusLabel: (json['status_label'] as String?) ?? '',
      messages: messages,
    );
  }
}

class KnowledgeRecord {
  const KnowledgeRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.kindLabel,
    required this.summary,
    required this.body,
    required this.url,
    required this.source,
    required this.isActive,
    required this.status,
  });

  final int id;
  final String title;
  final String kind;
  final String kindLabel;
  final String? summary;
  final String? body;
  final String? url;
  final String? source;
  final bool isActive;
  final String status;

  factory KnowledgeRecord.fromJson(Map<String, dynamic> json) {
    return KnowledgeRecord(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'text',
      kindLabel: (json['kind_label'] as String?) ?? 'Teks',
      summary: json['summary'] as String?,
      body: json['body'] as String?,
      url: json['url'] as String?,
      source: json['source'] as String?,
      isActive: json['is_active'] == true,
      status: (json['status'] as String?) ?? '',
    );
  }
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}
