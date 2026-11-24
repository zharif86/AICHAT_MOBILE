import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/records.dart';
import 'api_exception.dart';

class ChatApi {
  ChatApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? token;

  Future<String> login(String email, String password) async {
    final body = await _send(
      'POST',
      '/admin/login',
      body: {'email': email.trim(), 'password': password},
      timeout: const Duration(seconds: 20),
    );
    final value = body['token'];
    if (value is! String || value.isEmpty) {
      throw ApiException('Token log masuk tidak diterima.');
    }
    token = value;
    return value;
  }

  Future<AgentProfile> agent() async {
    final body = await _send('GET', '/api/ejen');
    return AgentProfile.fromJson(_data(body));
  }

  Future<PageResult<ConversationSummary>> conversations({
    int page = 1,
    String? status,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '20',
      'status': ?status,
    };
    final body = await _send('GET', '/api/perbualan', query: query);
    return _page(body, ConversationSummary.fromJson);
  }

  Future<ConversationDetail> conversation(int id) async {
    final body = await _send('GET', '/api/perbualan/$id');
    return ConversationDetail.fromJson(_data(body));
  }

  Future<ConversationDetail> createConversation() async {
    final body = await _send('POST', '/api/perbualan');
    return ConversationDetail.fromJson(_data(body));
  }

  Future<({String status, ChatMessage user, ChatMessage assistant})> sendMessage(
    int id,
    String message,
  ) async {
    final body = await _send(
      'POST',
      '/api/perbualan/$id/mesej',
      body: {'message': message},
      timeout: const Duration(seconds: 45),
    );
    final data = _data(body);
    return (
      status: (data['status'] as String?) ?? 'failed',
      user: ChatMessage.fromJson(_map(data['user_message'])),
      assistant: ChatMessage.fromJson(_map(data['assistant_message'])),
    );
  }

  Future<ConversationDetail> clearConversation(int id) async {
    final body = await _send('POST', '/api/perbualan/$id/kosongkan');
    return ConversationDetail.fromJson(_data(body));
  }

  Future<PageResult<KnowledgeRecord>> knowledge({int page = 1}) async {
    final body = await _send('GET', '/api/pengetahuan', query: {
      'page': '$page',
      'per_page': '50',
    });
    return _page(body, KnowledgeRecord.fromJson);
  }

  Future<KnowledgeRecord> saveKnowledge({
    int? id,
    required String title,
    required String kind,
    String? summary,
    String? body,
    String? url,
    String? source,
    required bool isActive,
  }) async {
    final payload = {
      'title': title,
      'kind': kind,
      'summary': _emptyToNull(summary),
      'body': kind == 'text' ? _emptyToNull(body) : null,
      'url': kind == 'link' ? _emptyToNull(url) : null,
      'source': _emptyToNull(source),
      'is_active': isActive,
    };
    final response = id == null
        ? await _send('POST', '/api/pengetahuan', body: payload)
        : await _send('PATCH', '/api/pengetahuan/$id', body: payload);
    return KnowledgeRecord.fromJson(_data(response));
  }

  Future<void> deleteKnowledge(int id) async {
    await _send('DELETE', '/api/pengetahuan/$id');
  }

  PageResult<T> _page<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) decode,
  ) {
    final raw = body['data'];
    final items = <T>[];
    if (raw is List) {
      for (final item in raw) {
        items.add(decode(_map(item)));
      }
    }
    final meta = body['meta'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
    return PageResult(
      items: items,
      currentPage: (metaMap['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (metaMap['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) => _map(body['data']);

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw ApiException('Bentuk jawapan pelayan tidak sah.');
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await switch (method) {
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body ?? {})),
        'PATCH' => _client.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.get(uri, headers: headers),
      }.timeout(timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Pelayan mengambil masa terlalu lama untuk menjawab.');
    } catch (_) {
      throw ApiException('Tidak dapat menghubungi pelayan di $baseUrl.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Object? body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      body = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return body;
      }
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
      return {};
    }
    var message = 'Permintaan tidak berjaya.';
    if (body is Map && body['message'] is String) {
      message = body['message'] as String;
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
