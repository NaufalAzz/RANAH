import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    required this.onBack,
    required this.onPreview,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onPreview;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _connectionMessage = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RanahColors.backgroundStart,
              RanahColors.backgroundMiddle,
              RanahColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Card(
                  color: RanahColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Kembali ke RANAH'),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: RanahColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Masuk Admin RANAH',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: RanahColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Panel ini hanya dapat digunakan setelah layanan autentikasi admin tersedia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: RanahColors.muted),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            key: const ValueKey('admin-username'),
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama pengguna atau email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Nama pengguna atau email wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const ValueKey('admin-password'),
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Kata sandi',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Kata sandi wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _connectionMessage = true);
                              }
                            },
                            child: const Text('Masuk'),
                          ),
                          if (_connectionMessage) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Layanan autentikasi belum terhubung. Tidak ada akses admin yang diberikan.',
                              key: ValueKey('admin-auth-unavailable'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9B1C1C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const Divider(height: 32),
                          OutlinedButton.icon(
                            onPressed: widget.onPreview,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Lihat pratinjau kerangka'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pratinjau tidak memverifikasi identitas dan tidak memberi hak akses admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: RanahColors.muted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
