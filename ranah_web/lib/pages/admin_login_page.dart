import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';
import '../widgets/ranah_background.dart';
import '../widgets/ranah_header.dart';

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
      body: RanahBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(RanahSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Card(
                  color: RanahColors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(RanahSpacing.xl),
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
                          const SizedBox(height: RanahSpacing.md),
                          const Center(child: RanahBrandMark(size: 64)),
                          const SizedBox(height: RanahSpacing.md),
                          Text(
                            'Masuk Admin RANAH',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: RanahColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: RanahSpacing.sm),
                          const Text(
                            'Panel ini hanya dapat digunakan setelah layanan autentikasi admin tersedia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: RanahColors.muted),
                          ),
                          const SizedBox(height: RanahSpacing.xl),
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
                          const SizedBox(height: RanahSpacing.lg),
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
                          const SizedBox(height: RanahSpacing.lg),
                          FilledButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _connectionMessage = true);
                              }
                            },
                            child: const Text('Masuk'),
                          ),
                          if (_connectionMessage) ...[
                            const SizedBox(height: RanahSpacing.md),
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
                          const Divider(height: RanahSpacing.xxl),
                          OutlinedButton.icon(
                            onPressed: widget.onPreview,
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Lihat pratinjau kerangka'),
                          ),
                          const SizedBox(height: RanahSpacing.sm),
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
