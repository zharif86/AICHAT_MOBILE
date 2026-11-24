import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:japen_ai/config/api_config.dart';
import 'package:japen_ai/main.dart';
import 'package:japen_ai/services/chat_api.dart';
import 'package:japen_ai/services/session_store.dart';
import 'package:japen_ai/state/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Session> signedOut() async {
    SharedPreferences.setMockInitialValues({});
    final session = Session(
      api: ChatApi(baseUrl: apiBaseUrl),
      store: SessionStore(),
    );
    await session.restore();
    return session;
  }

  testWidgets('login screen presents the workspace', (tester) async {
    final session = await signedOut();
    await tester.pumpWidget(JapenApp(session: session));
    expect(find.text('JapenAi'), findsOneWidget);
    expect(find.text('Log masuk'), findsOneWidget);
    expect(find.text('JABATAN PENERANGAN'), findsOneWidget);
  });

  testWidgets('empty credentials stay on the form', (tester) async {
    final session = await signedOut();
    await tester.pumpWidget(JapenApp(session: session));
    await tester.tap(find.text('Log masuk'));
    await tester.pump();
    expect(find.text('E-mel dan kata laluan diperlukan.'), findsOneWidget);
  });

  testWidgets('a malformed email is rejected locally', (tester) async {
    final session = await signedOut();
    await tester.pumpWidget(JapenApp(session: session));
    await tester.enterText(find.byKey(const Key('email')), 'bukan-emel');
    await tester.enterText(find.byKey(const Key('password')), 'rahsia');
    await tester.tap(find.text('Log masuk'));
    await tester.pump();
    expect(find.text('Masukkan e-mel yang sah.'), findsOneWidget);
  });
}
