import 'package:material_ui/material_ui.dart';

import '../services/api_exception.dart';
import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final agent = session.agent;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Eyebrow('Pentadbir'),
            const SizedBox(height: 6),
            const Text(
              'Akaun',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 20),
            _Panel(
              children: [
                _Row(label: 'E-mel', value: session.email ?? '—'),
                const Divider(height: 1),
                _Row(label: 'Ejen aktif', value: agent?.name ?? 'Tidak dimuatkan'),
                const Divider(height: 1),
                _Row(
                  label: 'Status ejen',
                  value: agent == null
                      ? '—'
                      : agent.isActive
                      ? 'Aktif'
                      : 'Tidak aktif',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Sesi ini menggunakan token pembawa yang disimpan pada peranti ini. Log keluar memadam token tempatan.',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: Palette.inkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () async {
                try {
                  await session.refreshAgent();
                  if (context.mounted) {
                    showNote(context, 'Maklumat ejen dikemas kini.');
                  }
                } on ApiException catch (error) {
                  if (context.mounted) {
                    showNote(context, error.message);
                  }
                }
              },
              child: const Text('Segarkan ejen'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Palette.ink),
                onPressed: () => session.logout(),
                child: const Text('Log keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.line),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: Palette.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
