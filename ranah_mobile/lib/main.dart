
import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const RanahApp());
}

class RanahApp extends StatelessWidget {
  const RanahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const GunungPage(),
    );
  }
}

class GunungPage extends StatefulWidget {
  const GunungPage({super.key});

  @override
  State<GunungPage> createState() => _GunungPageState();
}

class _GunungPageState extends State<GunungPage> {
  final ApiService apiService = ApiService();

  late Future<List<dynamic>> futureGunung;

  @override
  void initState() {
    super.initState();
    futureGunung = apiService.getGunung();
  }

  void muatUlang() {
    setState(() {
      futureGunung = apiService.getGunung();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uji API RANAH'),
        actions: [
          IconButton(
            onPressed: muatUlang,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureGunung,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil data API',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: muatUlang,
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
            return const Center(
              child: Text('Belum ada data gunung.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final permintaan = apiService.getGunung();

              setState(() {
                futureGunung = permintaan;
              });

              await permintaan;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              itemCount: daftarGunung.length,
              itemBuilder: (context, index) {
                final gunung = daftarGunung[index];

                final nama = gunung['nama'] ?? 'Tanpa nama';
                final kabupaten = gunung['kabupaten'] ?? '-';
                final provinsi = gunung['provinsi'] ?? '-';
                final status =
                    gunung['status_aktivitas'] ?? 'Belum tersedia';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.landscape),
                    ),
                    title: Text(
                      nama.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$kabupaten, $provinsi\n'
                        'Status data: $status',
                      ),
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
