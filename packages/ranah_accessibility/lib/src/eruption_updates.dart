import 'package:flutter/material.dart';
import 'eruption_center.dart';
import 'eruption_store.dart';

class EruptionUpdates extends StatefulWidget {
  const EruptionUpdates({required this.loadVolcanoes, this.onBack, super.key});
  final VolcanoListLoader loadVolcanoes;
  final VoidCallback? onBack;
  @override
  State<EruptionUpdates> createState() => _EruptionUpdatesState();
}

class _EruptionUpdatesState extends State<EruptionUpdates> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _cached = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    Map<String, dynamic> state = {};
    try {
      state = await EruptionStore().read();
    } catch (_) {}
    final selected = state['selected'];
    try {
      final items = await widget.loadVolcanoes();
      if (!mounted) return;
      setState(() {
        _items = selected is Map
            ? items
                  .where((item) => '${item['id']}' == '${selected['id']}')
                  .toList()
            : items;
        _cached = false;
        _message = selected is Map
            ? 'Pembaruan gunung pilihan. Buka Gunung yang Saya Ikuti untuk mengganti pilihan dan menyimpan laporan.'
            : 'Belum memilih gunung; menampilkan aktivitas yang tersedia dari server.';
      });
    } catch (_) {
      if (!mounted) return;
      final detail = state['detail'];
      final cached = detail is Map ? detail['gunung'] : selected;
      setState(() {
        _items = cached is Map ? [Map<String, dynamic>.from(cached)] : [];
        _cached = true;
        _message =
            'Pembaruan belum dapat dimuat. Periksa koneksi dan konfigurasi API. Data tersimpan bukan kondisi terkini.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: Theme.of(context).colorScheme.onSurface,
        displayColor: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.onBack != null)
            TextButton(onPressed: widget.onBack, child: const Text('Kembali')),
          const Text(
            'Pembaruan Gunung Api',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Informasi aktivitas dari sumber, bukan perintah evakuasi otomatis. Perhatikan waktu data dan arahan petugas.',
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!),
            ),
          if (_loading) const LinearProgressIndicator(),
          FilledButton(
            onPressed: _loading ? null : _load,
            child: const Text('Perbarui informasi'),
          ),
          if (!_loading && _items.isEmpty)
            const Text('Belum ada informasi gunung yang tersedia.'),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['nama']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${item['status_aktivitas'] ?? 'Status belum tersedia'}${_cached ? ' · TERSIMPAN' : ''}',
                  ),
                  Text(
                    'Sumber: ${item['sumber_data'] ?? '-'}\nWaktu sumber: ${item['waktu_pengambilan'] ?? 'Tidak diketahui'}',
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
