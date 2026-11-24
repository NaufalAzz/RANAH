import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Categories used by the BNPB archive importer. Preserve additional editorial categories.
List<String> newsCategories(Iterable<String> available, String selected) =>
    {
        'Banjir',
        'Banjir dan longsor',
        'Tanah longsor',
        'Erupsi gunung api',
        'Cuaca ekstrem',
        ...available.map((v) => v.trim()),
        selected,
      }.where((v) => v.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

const _provinces = [
  'Aceh',
  'Sumatera Utara',
  'Sumatera Barat',
  'Riau',
  'Kepulauan Riau',
  'Jambi',
  'Sumatera Selatan',
  'Kepulauan Bangka Belitung',
  'Bengkulu',
  'Lampung',
  'Banten',
  'DKI Jakarta',
  'Jawa Barat',
  'Jawa Tengah',
  'DI Yogyakarta',
  'Jawa Timur',
  'Bali',
  'Nusa Tenggara Barat',
  'Nusa Tenggara Timur',
  'Kalimantan Barat',
  'Kalimantan Tengah',
  'Kalimantan Selatan',
  'Kalimantan Timur',
  'Kalimantan Utara',
  'Sulawesi Utara',
  'Gorontalo',
  'Sulawesi Tengah',
  'Sulawesi Barat',
  'Sulawesi Selatan',
  'Sulawesi Tenggara',
  'Maluku',
  'Maluku Utara',
  'Papua',
  'Papua Barat',
  'Papua Barat Daya',
  'Papua Tengah',
  'Papua Pegunungan',
  'Papua Selatan',
];

String _regionKey(String value) {
  final key = value
      .trim()
      .toLowerCase()
      .replaceAll('sumatra', 'sumatera')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^provinsi\s+'), '');
  return switch (key) {
    'daerah istimewa yogyakarta' ||
    'd.i. yogyakarta' ||
    'diy' => 'di yogyakarta',
    'daerah khusus ibukota jakarta' ||
    'daerah khusus jakarta' ||
    'jakarta' => 'dki jakarta',
    _ => key.replaceFirst(RegExp(r'^kab\.\s*'), 'kabupaten '),
  };
}

bool newsRegionMatches(String? location, String selected) {
  if (selected.isEmpty) return true;
  final query = _regionKey(selected);
  for (final part in (location ?? '').split(RegExp(r'[,;/]'))) {
    final key = _regionKey(part);
    if (key == query ||
        key.replaceFirst(RegExp(r'^(kabupaten|kota|kecamatan) '), '') ==
            query) {
      return true;
    }
  }
  return false;
}

// Older imports retain a date without a time in the bulletin's labelled lines.
final _bulletinDayLine = RegExp(
  r'^Tanggal (kejadian|akhir kejadian) menurut buletin: (\d{4})-(\d{2})-(\d{2})\.(?=\s|$)',
  multiLine: true,
);

DateTimeRange? bnpbBulletinDays(String? source, String body) {
  if (!(source?.toUpperCase().contains('BNPB') ?? false)) return null;
  DateTime? start;
  DateTime? end;
  for (final match in _bulletinDayLine.allMatches(body)) {
    final year = int.parse(match[2]!);
    final month = int.parse(match[3]!);
    final day = int.parse(match[4]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) continue;
    if (match[1] == 'kejadian') {
      start = date;
    } else {
      end = date;
    }
  }
  if (start == null) return null;
  return DateTimeRange(
    start: start,
    end: end != null && !end.isBefore(start) ? end : start,
  );
}

String newsDayRangeLabel(DateTimeRange range) {
  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  return range.start == range.end
      ? date(range.start)
      : '${date(range.start)} – ${date(range.end)}';
}

bool newsDateMatches(
  DateTime? event,
  DateTimeRange? range, {
  DateTimeRange? bulletinDays,
}) {
  if (range == null) return true;
  final start =
      bulletinDays?.start ??
      (event == null ? null : DateUtils.dateOnly(event.toLocal()));
  if (start == null) return false;
  final end = bulletinDays?.end ?? start;
  return !end.isBefore(range.start) && !start.isAfter(range.end);
}

ThemeData _pickerTheme(BuildContext context) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF72CDD6),
    brightness: Brightness.dark,
    surface: const Color(0xFF122F47),
  ),
  datePickerTheme: DatePickerThemeData(
    rangePickerHeaderHeadlineStyle: TextStyle(
      fontSize: MediaQuery.sizeOf(context).width < 430 ? 14 : 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  visualDensity: Theme.of(context).visualDensity,
);

class NewsDateRangeField extends StatelessWidget {
  const NewsDateRangeField({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final range = value;
    return _FilterButton(
      icon: Icons.date_range_outlined,
      label: 'Tanggal kejadian',
      value: range == null ? 'Semua tanggal' : newsDayRangeLabel(range),
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(1),
          lastDate: DateTime(2100, 12, 31),
          initialDateRange: range,
          initialEntryMode:
              MediaQuery.sizeOf(context).width < 360 ||
                  MediaQuery.textScalerOf(context).scale(16) >= 24
              ? DatePickerEntryMode.input
              : DatePickerEntryMode.calendar,
          helpText: 'Rentang tanggal kejadian',
          saveText: 'Terapkan',
          confirmText: 'Terapkan',
          cancelText: 'Batal',
          fieldStartLabelText: 'Dari tanggal',
          fieldEndLabelText: 'Sampai tanggal',
          builder: (context, child) {
            final picker = Localizations.override(
              context: context,
              locale: const Locale('id'),
              delegates: GlobalMaterialLocalizations.delegates,
              child: Theme(data: _pickerTheme(context), child: child!),
            );
            if (MediaQuery.sizeOf(context).width < 720) return picker;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 640,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: picker,
                ),
              ),
            );
          },
        );
        if (picked != null && context.mounted) onChanged(picked);
      },
    );
  }
}

class NewsRegionField extends StatelessWidget {
  const NewsRegionField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.locations,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final Iterable<String?> locations;

  @override
  Widget build(BuildContext context) => _FilterButton(
    icon: Icons.place_outlined,
    label: 'Wilayah',
    value: value.isEmpty ? 'Semua wilayah' : value,
    onTap: () async {
      final options = {
        ..._provinces,
        for (final location in locations.whereType<String>())
          for (final part in location.split(RegExp(r'[,;/]')))
            if (part.trim().isNotEmpty) part.trim(),
      }.toList()..sort();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => Theme(
          data: _pickerTheme(context),
          child: _RegionDialog(options: options, selected: value),
        ),
      );
      if (result != null && context.mounted) onChanged(result);
    },
  );
}

class _RegionDialog extends StatefulWidget {
  const _RegionDialog({required this.options, required this.selected});
  final List<String> options;
  final String selected;
  @override
  State<_RegionDialog> createState() => _RegionDialogState();
}

class _RegionDialogState extends State<_RegionDialog> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final key = _regionKey(_query);
    final options = widget.options.where(
      (option) => _regionKey(option).contains(key),
    );
    final choices = [
      if (key.isEmpty) '',
      if (key.isNotEmpty && !options.any((o) => _regionKey(o) == key)) _query,
      ...options,
    ];
    return AlertDialog(
      title: const Text('Pilih wilayah'),
      content: SizedBox(
        width: 400,
        height: 380,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Provinsi, kabupaten, atau kota',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (s) => setState(() => _query = s.trim()),
              onSubmitted: (s) => Navigator.pop(context, s.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: choices.length,
                itemBuilder: (context, i) {
                  final option = choices[i];
                  return ListTile(
                    title: Text(option.isEmpty ? 'Semua wilayah' : option),
                    trailing: _regionKey(option) == _regionKey(widget.selected)
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF133E59),
      side: const BorderSide(color: Color(0xFF7699AD)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      minimumSize: const Size(48, 54),
    ),
    onPressed: onTap,
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF9EE0E5)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB9D2DF)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.expand_more, size: 18),
      ],
    ),
  );
}
