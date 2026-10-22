import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Layar uji API yang sudah ada sebelum fondasi UI dibuat.
/// Tetap dapat dibuka melalui route `/uji-api-gunung`.
class GunungApiPage extends StatefulWidget {
  const GunungApiPage({super.key});

  @override
  State<GunungApiPage> createState() => _GunungApiPageState();
}

class _GunungApiPageState extends State<GunungApiPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _futureGunung;

  @override
  void initState() {
    super.initState();
    _futureGunung = _apiService.getGunung();
  }

  void _muatUlang() {
    setState(() => _futureGunung = _apiService.getGunung());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uji API RANAH'),
        actions: [
          IconButton(
            onPressed: _muatUlang,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureGunung,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil data API',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _muatUlang,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final daftarGunung = snapshot.data ?? [];
          if (daftarGunung.isEmpty) {
            return const Center(child: Text('Belum ada data gunung.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              final request = _apiService.getGunung();
              setState(() => _futureGunung = request);
              await request;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: daftarGunung.length,
              itemBuilder: (context, index) {
                final gunung = daftarGunung[index];
                final nama = gunung['nama'] ?? 'Tanpa nama';
                final kabupaten = gunung['kabupaten'] ?? '-';
                final provinsi = gunung['provinsi'] ?? '-';
                final status = gunung['status_aktivitas'] ?? 'Belum tersedia';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.landscape),
                    ),
                    title: Text(
                      nama.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('$kabupaten, $provinsi\nStatus data: $status'),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
