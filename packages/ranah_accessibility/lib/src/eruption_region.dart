import 'package:flutter/material.dart';

/// Volcano names are matched as whole phrases, avoiding Merapi/Marapi confusion.
const eruptionProvinces = <String, String>{
  'Marapi': 'Sumatera Barat',
  'Tandikat': 'Sumatera Barat',
  'Talang': 'Sumatera Barat',
  'Kerinci': 'Jambi',
  'Sinabung': 'Sumatera Utara',
  'Sibayak': 'Sumatera Utara',
  'Dempo': 'Sumatera Selatan',
  'Kaba': 'Bengkulu',
  'Anak Krakatau': 'Lampung',
  'Krakatau': 'Lampung',
  'Seulawah Agam': 'Aceh',
  'Peut Sague': 'Aceh',
  'Burni Telong': 'Aceh',
  'Sorik Marapi': 'Sumatera Utara',
  'Merapi': 'Daerah Istimewa Yogyakarta',
  'Semeru': 'Jawa Timur',
  'Bromo': 'Jawa Timur',
  'Raung': 'Jawa Timur',
  'Ijen': 'Jawa Timur',
  'Slamet': 'Jawa Tengah',
  'Dieng': 'Jawa Tengah',
  'Merbabu': 'Jawa Tengah',
  'Tangkuban Parahu': 'Jawa Barat',
  'Guntur': 'Jawa Barat',
  'Papandayan': 'Jawa Barat',
  'Galunggung': 'Jawa Barat',
  'Agung': 'Bali',
  'Batur': 'Bali',
  'Rinjani': 'Nusa Tenggara Barat',
  'Tambora': 'Nusa Tenggara Barat',
  'Lewotobi': 'Nusa Tenggara Timur',
  'Lewotolok': 'Nusa Tenggara Timur',
  'Ili Lewotolok': 'Nusa Tenggara Timur',
  'Iya': 'Nusa Tenggara Timur',
  'Egon': 'Nusa Tenggara Timur',
  'Inielika': 'Nusa Tenggara Timur',
  'Ebulobo': 'Nusa Tenggara Timur',
  'Ibu': 'Maluku Utara',
  'Dukono': 'Maluku Utara',
  'Gamalama': 'Maluku Utara',
  'Gamkonora': 'Maluku Utara',
  'Karangetang': 'Sulawesi Utara',
  'Ruang': 'Sulawesi Utara',
  'Awu': 'Sulawesi Utara',
  'Soputan': 'Sulawesi Utara',
  'Lokon': 'Sulawesi Utara',
};
String? eruptionVolcano(String title) {
  final names = eruptionProvinces.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in names) {
    if (RegExp(
      r'\b' + RegExp.escape(name) + r'\b',
      caseSensitive: false,
    ).hasMatch(title))
      return name;
  }
  return null;
}

String? eruptionIsland(String? province) {
  final p = province?.toLowerCase().replaceAll('sumatra', 'sumatera') ?? '';
  if (p.contains('sumatera') ||
      [
        'aceh',
        'jambi',
        'riau',
        'bengkulu',
        'lampung',
        'bangka',
        'belitung',
      ].any(p.contains))
    return 'Sumatra';
  if (p.contains('jawa') ||
      p.contains('yogyakarta') ||
      p.contains('banten') ||
      p.contains('jakarta'))
    return 'Jawa';
  if (p.contains('kalimantan')) return 'Kalimantan';
  if (p.contains('sulawesi') || p.contains('gorontalo')) return 'Sulawesi';
  if (p.contains('maluku')) return 'Maluku';
  if (p.contains('papua')) return 'Papua';
  if (p.contains('bali')) return 'Bali';
  if (p.contains('nusa tenggara')) return 'Nusa Tenggara';
  return null;
}

List<T> localEruptionNews<T>(
  List<T> items,
  String Function(T) title,
  String? province,
) {
  final island = eruptionIsland(province);
  if (island == null) return items;
  final result = items
      .where(
        (e) =>
            eruptionIsland(eruptionProvinces[eruptionVolcano(title(e))]) ==
            island,
      )
      .toList();
  result.sort((a, b) {
    int rank(T e) =>
        eruptionProvinces[eruptionVolcano(title(e))]?.toLowerCase() ==
            province?.toLowerCase()
        ? 0
        : 1;
    final ranked = rank(a).compareTo(rank(b));
    return ranked != 0 ? ranked : items.indexOf(a).compareTo(items.indexOf(b));
  });
  return result;
}

class VolcanoNewsFilter extends StatefulWidget {
  const VolcanoNewsFilter({
    required this.titles,
    required this.onChanged,
    required this.child,
    super.key,
  });
  final List<String> titles;
  final ValueChanged<String?> onChanged;
  final Widget child;
  @override
  State<VolcanoNewsFilter> createState() => _VolcanoNewsFilterState();
}

class _VolcanoNewsFilterState extends State<VolcanoNewsFilter> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final names =
        widget.titles.map(eruptionVolcano).whereType<String>().toSet().toList()
          ..sort();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Pilih gunung',
              filled: true,
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua gunung')),
              for (final name in names)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: (value) {
              setState(() => selected = value);
              widget.onChanged(value == '' ? null : value);
            },
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class LocationNewsScope extends StatelessWidget {
  const LocationNewsScope({
    required this.province,
    required this.child,
    super.key,
  });
  final String? province;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final island = eruptionIsland(province);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF102F49),
          padding: const EdgeInsets.all(10),
          child: Text(
            island == null
                ? 'Berita erupsi seluruh Indonesia'
                : 'Erupsi di $island · Prioritas $province',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class VolcanoNewsPicker extends StatefulWidget {
  const VolcanoNewsPicker({
    required this.titles,
    required this.onChanged,
    super.key,
  });
  final List<String> titles;
  final ValueChanged<String?> onChanged;
  @override
  State<VolcanoNewsPicker> createState() => _VolcanoNewsPickerState();
}

class _VolcanoNewsPickerState extends State<VolcanoNewsPicker> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final names =
        widget.titles.map(eruptionVolcano).whereType<String>().toSet().toList()
          ..sort();
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      dropdownColor: const Color(0xFF123D5B),
      decoration: InputDecoration(
        labelText: 'Gunung',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF123D5B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Semua gunung')),
        for (final name in names)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: (value) {
        setState(() => selected = value);
        widget.onChanged(value == '' ? null : value);
      },
    );
  }
}

String readableNewsBody(String title, String body) {
  final clean = body
      .split(
        RegExp(
          r'\n\n(?:Pratinjau judul|Pratinjau dari penerbit|Ringkasan dari RSS|Pratinjau dari indeks)',
        ),
      )
      .first
      .trim();
  return clean == title.trim() || clean.isEmpty
      ? 'Penjelasan artikel belum berhasil diambil.'
      : clean;
}
