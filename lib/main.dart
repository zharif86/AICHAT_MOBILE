import 'package:material_ui/material_ui.dart';

import 'config/api_config.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/chat_api.dart';
import 'services/session_store.dart';
import 'state/session.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';
import 'widgets/chrome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(api: ChatApi(baseUrl: apiBaseUrl), store: SessionStore());
  await session.restore();
  runApp(JapenApp(session: session));
}

class JapenApp extends StatelessWidget {
  const JapenApp({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: session,
      child: MaterialApp(
        title: 'JapenAi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) => PhoneFrame(child: child ?? const SizedBox.shrink()),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Palette.sage)),
      );
    }
    if (!session.signedIn) {
      return const LoginScreen();
    }
    return const HomeShell();
  }
}
