import 'package:material_ui/material_ui.dart';

import '../state/session.dart';
import '../theme/palette.dart';
import '../widgets/chrome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'E-mel dan kata laluan diperlukan.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Masukkan e-mel yang sah.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await SessionScope.of(context).login(email, password);
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(),
              const SizedBox(height: 28),
              const Eyebrow('Jabatan Penerangan'),
              const SizedBox(height: 8),
              const Text(
                'JapenAi',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 42,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  color: Palette.ink,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ruang kerja pembantu maya untuk pegawai. Jawapan berpandukan arahan rasmi dan pangkalan pengetahuan.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15.5,
                  height: 1.5,
                  color: Palette.inkSoft,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                key: const Key('email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'E-mel',
                  hintText: 'nama@jabatan.gov.my',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('password'),
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Kata laluan',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Palette.danger,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log masuk'),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Akses terhad kepada pentadbir yang dibenarkan.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12.5,
                  color: Palette.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
