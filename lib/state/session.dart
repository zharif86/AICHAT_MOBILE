import 'package:material_ui/material_ui.dart';

import '../models/records.dart';
import '../services/api_exception.dart';
import '../services/chat_api.dart';
import '../services/session_store.dart';

class Session extends ChangeNotifier {
  Session({required this.api, required this.store});

  final ChatApi api;
  final SessionStore store;

  bool ready = false;
  String? token;
  String? email;
  AgentProfile? agent;

  bool get signedIn => token != null && token!.isNotEmpty;

  Future<void> restore() async {
    final saved = await store.read();
    token = saved.token;
    email = saved.email;
    if (signedIn) {
      api.token = token;
      try {
        agent = await api.agent();
      } on ApiException catch (error) {
        if (error.unauthorized) {
          await _clear();
        }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final issued = await api.login(email, password);
      token = issued;
      this.email = email.trim();
      api.token = issued;
      await store.write(issued, this.email!);
      try {
        agent = await api.agent();
      } on ApiException {
        agent = null;
      }
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> refreshAgent() async {
    agent = await api.agent();
    notifyListeners();
  }

  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      if (error.unauthorized) {
        await logout();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    token = null;
    email = null;
    agent = null;
    api.token = null;
    await store.clear();
  }
}

class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child})
    : super(notifier: session);

  static Session of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope missing');
    return scope!.notifier!;
  }
}
