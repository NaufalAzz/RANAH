import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({required this.onExit, super.key});

  final VoidCallback onExit;

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selected = 0;

  static const _sections = <_AdminSection>[
    _AdminSection(
      title: 'Data Gunung & Aktivitas',
      icon: Icons.volcano_outlined,
      requirement: 'FR-35',
      details: [
        'Status dan tanggal pembaruan',
        'Rekomendasi, koordinat, dan radius',
        'Foto serta impor daftar gunung dari CSV',
      ],
    ),
    _AdminSection(
      title: 'Titik Evakuasi, Rute & Zona',
      icon: Icons.route_outlined,
      requirement: 'FR-36',
      details: [
        'Titik evakuasi',
        'Rute evakuasi dan unggah GeoJSON',
        'Zona potensi bencana',
      ],
    ),
    _AdminSection(
      title: 'Berita',
      icon: Icons.newspaper_outlined,
      requirement: 'FR-37',
      details: ['Pengelolaan konten berita'],
    ),
    _AdminSection(
      title: 'Kontak Darurat',
      icon: Icons.contact_phone_outlined,
      requirement: 'FR-37',
      details: ['Pengelolaan kontak darurat'],
    ),
    _AdminSection(
      title: 'Panduan Mitigasi',
      icon: Icons.health_and_safety_outlined,
      requirement: 'FR-37',
      details: ['Pengelolaan konten panduan mitigasi'],
    ),
    _AdminSection(
      title: 'Log Notifikasi',
      icon: Icons.notifications_outlined,
      requirement: 'ID tidak terbaca pada ekstrak BRD',
      details: ['Melihat log notifikasi otomatis'],
    ),
    _AdminSection(
      title: 'Pengaduan',
      icon: Icons.report_problem_outlined,
      requirement: 'ID tidak terbaca pada ekstrak BRD',
      details: ['Peninjauan dan pengelolaan pengaduan'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selected];
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!compact) _sidebar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(compact ? 16 : 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (compact) ...[
                                _mobileSectionPicker(),
                                const SizedBox(height: 20),
                              ],
                              Text(
                                section.title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: RanahColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Acuan kebutuhan ${section.requirement}',
                                style: const TextStyle(
                                  color: RanahColors.muted,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5DC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE6BB53),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF795B13),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'MODE PRATINJAU — belum terhubung ke server. Tidak ada data yang dapat diubah atau disimpan.',
                                        style: TextStyle(
                                          color: Color(0xFF5F4A15),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Card(
                                elevation: 1,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cakupan fitur',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: RanahColors.ink,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      for (final detail in section.details)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 8,
                                                color: RanahColors.primary,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  detail,
                                                  style: const TextStyle(
                                                    color: RanahColors.ink,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Divider(height: 24),
                                      const Text(
                                        'Aksi pengelolaan akan tersedia setelah autentikasi dan penyimpanan server diimplementasikan.',
                                        style: TextStyle(
                                          color: RanahColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      return Container(
        height: 66,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
        color: RanahColors.headerStart,
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'RANAH  /  Panel Admin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 16 : 17,
                ),
              ),
            ),
            if (compact)
              IconButton(
                tooltip: 'Keluar pratinjau',
                onPressed: widget.onExit,
                icon: const Icon(Icons.logout, color: Colors.white),
              )
            else
              TextButton.icon(
                onPressed: widget.onExit,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Keluar pratinjau',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _sidebar() => Container(
    width: 270,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'MENU PENGELOLAAN',
            style: TextStyle(
              color: RanahColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
        ),
        for (var i = 0; i < _sections.length; i++) _navItem(i),
      ],
    ),
  );

  Widget _mobileSectionPicker() => DropdownButtonFormField<int>(
    key: const ValueKey('admin-section-picker'),
    initialValue: _selected,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Menu pengelolaan',
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
    items: [
      for (var i = 0; i < _sections.length; i++)
        DropdownMenuItem(
          value: i,
          child: Text(
            _sections[i].title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: (value) {
      if (value != null) setState(() => _selected = value);
    },
  );

  Widget _navItem(int index) {
    final section = _sections[index];
    final selected = index == _selected;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFF0EBFA),
        leading: Icon(
          section.icon,
          color: selected ? RanahColors.primary : RanahColors.muted,
        ),
        title: Text(
          section.title,
          style: TextStyle(
            color: selected ? RanahColors.primary : RanahColors.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () => setState(() => _selected = index),
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.title,
    required this.icon,
    required this.requirement,
    required this.details,
  });

  final String title;
  final IconData icon;
  final String requirement;
  final List<String> details;
}
