import 'package:flutter/material.dart';
import 'official_krb_reference.dart';

class OfficialKrbMapButton extends StatelessWidget {
  const OfficialKrbMapButton({required this.name, super.key});
  final String name;

  @override
  Widget build(BuildContext context) {
    final reference = officialKrbReference(name);
    if (reference == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      key: ValueKey('official-krb-${reference.name}'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF164D79),
        side: const BorderSide(color: Color(0xFF7AB2D2)),
      ),
      icon: const Icon(Icons.map_outlined, size: 20),
      label: const Text('Lihat peta KRB resmi'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _OfficialKrbMapPage(reference: reference),
        ),
      ),
    );
  }
}

class _OfficialKrbMapPage extends StatefulWidget {
  const _OfficialKrbMapPage({required this.reference});
  final OfficialKrbReference reference;

  @override
  State<_OfficialKrbMapPage> createState() => _OfficialKrbMapPageState();
}

class _OfficialKrbMapPageState extends State<_OfficialKrbMapPage> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    return Scaffold(
      backgroundColor: const Color(0xFF102B43),
      appBar: AppBar(title: Text('Peta KRB ${reference.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${OfficialKrbReference.source} · Tahun ${reference.year}\n'
              'Cubit atau gulir untuk memperbesar. Peta memerlukan internet. '
              'Ikuti arahan PVMBG/BPBD terkini.',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 8,
              child: Image.network(
                reference.imageUrl,
                key: ValueKey(_attempt),
                semanticLabel:
                    'Peta KRB resmi ${reference.name}, tahun ${reference.year}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, _, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Peta belum dapat dimuat. Periksa koneksi internet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => setState(() => _attempt++),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
