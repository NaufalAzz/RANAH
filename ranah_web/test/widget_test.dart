import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/main.dart';
import 'package:ranah_web/widgets/illustrative_map.dart';
import 'package:ranah_web/pages/admin_login_page.dart';
import 'package:ranah_web/pages/admin_panel_page.dart';
import 'package:ranah_web/theme/ranah_theme.dart';

void main() {
  test(
    'shared text colors meet the 4.5:1 AA ratio on their tested surfaces',
    () {
      expect(
        _contrastRatio(RanahColors.muted, Colors.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(RanahColors.eruption, Colors.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(RanahColors.headerMuted, RanahColors.headerStart),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  testWidgets('font size setting scales text and navigation has 48dp targets', (
    tester,
  ) async {
    for (final size in [const Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MyApp());
      for (final destination in ['home', 'map', 'news', 'menu']) {
        final nav = find.byKey(ValueKey('ranah-nav-$destination'));
        expect(tester.getSize(nav).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(nav).height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);

      if (size.width == 390) {
        final label = find.text('Awal').first;
        final originalHeight = tester.getSize(label).height;
        await tester.tap(find.byKey(const ValueKey('text-size-control')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('130%'));
        await tester.pumpAndSettle();
        expect(tester.getSize(label).height, greaterThan(originalHeight));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('admin login validates required fields and never grants access', (
    tester,
  ) async {
    var previewOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminLoginPage(
          onBack: () {},
          onPreview: () => previewOpened = true,
        ),
      ),
    );

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Nama pengguna atau email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('admin-username')),
      'contoh',
    );
    await tester.enterText(
      find.byKey(const ValueKey('admin-password')),
      'rahasia',
    );
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Layanan autentikasi belum terhubung. Tidak ada akses admin yang diberikan.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AdminPanelPage), findsNothing);

    await tester.ensureVisible(find.text('Lihat pratinjau kerangka'));
    await tester.tap(find.text('Lihat pratinjau kerangka'));
    expect(previewOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'admin preview navigation and server-unavailable state fit layouts',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(home: AdminPanelPage(onExit: () {})),
        );
        expect(
          find.textContaining('belum terhubung ke server.'),
          findsOneWidget,
        );
        expect(find.text('Data Gunung & Aktivitas'), findsWidgets);
        expect(tester.takeException(), isNull);

        if (size.width < 780) {
          await tester.tap(find.byKey(const ValueKey('admin-section-picker')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pengaduan').last);
        } else {
          await tester.tap(find.text('Pengaduan').last);
        }
        await tester.pumpAndSettle();
        expect(
          find.text('Acuan kebutuhan ID tidak terbaca pada ekstrak BRD'),
          findsOneWidget,
        );
        expect(
          find.text('Peninjauan dan pengelolaan pengaduan'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'activity search filters, report opens, KRB toggles, and back returns',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Peta').first);
      await tester.pumpAndSettle();
      expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);

      await tester.tap(find.text('Laporan Aktivitas Gunung'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar Tingkat Aktivitas Gunung Api'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Jawa Timur');
      await tester.pumpAndSettle();
      expect(find.text('Gunung Semeru'), findsOneWidget);
      expect(find.text('Gunung Bromo'), findsOneWidget);
      expect(find.text('Gunung Anak Krakatau'), findsNothing);

      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      final reportButton = find.text('Lihat Laporan').first;
      await tester.ensureVisible(reportButton);
      await tester.tap(reportButton);
      await tester.pumpAndSettle();
      expect(find.text('Laporan Gunung Api - DATA CONTOH'), findsOneWidget);

      final krbButton = find.text('Tampilkan Peta KRB');
      await tester.ensureVisible(krbButton);
      await tester.tap(krbButton);
      await tester.pumpAndSettle();
      expect(find.text('Sembunyikan Zona KRB'), findsOneWidget);
      expect(
        find.text('Zona ini hanya ilustrasi perkiraan, bukan batas KRB resmi.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Kembali').first);
      await tester.pumpAndSettle();
      expect(find.text('Aktivitas Gunung Api'), findsOneWidget);
    },
  );

  testWidgets('map mountain cards open report and return to map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Peta').first);
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);

    final mapRect = tester.getRect(find.byType(IllustrativeMap));
    await tester.tapAt(mapRect.center);
    await tester.pumpAndSettle();

    expect(find.text('LOKASI CONTOH'), findsOneWidget);
    final mountain = find.text('Gunung Marapi').first;
    await tester.ensureVisible(mountain);
    await tester.tap(mountain);
    await tester.pumpAndSettle();
    expect(find.text('Laporan Gunung Api - DATA CONTOH'), findsOneWidget);

    await tester.tap(find.text('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);
  });

  testWidgets('Map opens on the main map and location action opens Padang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Peta').first);
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);
    expect(find.text('LOKASI CONTOH'), findsNothing);

    await tester.tap(find.text('Temukan Lokasi Saya'));
    await tester.pumpAndSettle();
    expect(find.text('LOKASI CONTOH'), findsOneWidget);
    expect(find.text('Bukan lokasi perangkat Anda'), findsOneWidget);

    await tester.tap(find.text('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);
    expect(find.text('LOKASI CONTOH'), findsNothing);
  });

  testWidgets('evacuation route opens from map details and returns to them', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Peta').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temukan Lokasi Saya'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Geser pin merah'), findsOneWidget);
      final pin = find.byKey(const ValueKey('manual-location-pin'));
      final beforeDrag = tester.getRect(pin);
      await tester.drag(pin, const Offset(70, -18));
      await tester.pumpAndSettle();
      expect(find.text('LOKASI PILIHAN MANUAL'), findsOneWidget);
      expect(find.text('Titik ilustratif pada peta'), findsOneWidget);
      expect(tester.getRect(pin).center.dx, greaterThan(beforeDrag.center.dx));
      expect(tester.takeException(), isNull);

      final routeCard = find.byKey(const ValueKey('evacuation-route-card'));
      await tester.ensureVisible(routeCard);
      await tester.tap(routeCard);
      await tester.pumpAndSettle();
      expect(find.text('Jalur Evakuasi'), findsOneWidget);
      expect(find.text('Rute Evakuasi Terdekat'), findsOneWidget);
      expect(find.text('Jenis bencana'), findsOneWidget);
      expect(find.text('Jarak rute'), findsOneWidget);
      expect(find.text('Estimasi jalan kaki'), findsOneWidget);
      expect(find.text('DATA SIMULASI'), findsOneWidget);
      expect(
        find.textContaining('bukan arahan evakuasi resmi'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('evacuation-route-back')));
      await tester.pumpAndSettle();
      expect(find.text('LOKASI PILIHAN MANUAL'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('evacuation-route-card')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('news filters, opens the selected story, and returns to News', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    expect(find.text('Berita & Peristiwa'), findsOneWidget);
    expect(find.text('CONTOH · ERUPSI'), findsOneWidget);

    await tester.tap(find.text('Pengungsian'));
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh Berita: Informasi Posko Pengungsian'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh Berita: Informasi Aktivitas Erupsi Gunung'),
      findsNothing,
    );

    await tester.tap(find.text('Contoh Berita: Informasi Posko Pengungsian'));
    await tester.pumpAndSettle();
    expect(
      find.text('Halaman ini menggunakan konten lokal contoh untuk'),
      findsNothing,
    );
    expect(
      find.textContaining('Halaman ini menggunakan konten lokal contoh'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Konten demonstrasi — bukan berita terkini yang telah diverifikasi.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita & Peristiwa'), findsOneWidget);
  });

  testWidgets('news and detail fit a desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    expect(find.text('Berita & Peristiwa'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.text('Contoh Berita: Informasi Aktivitas Erupsi Gunung'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Konten demonstrasi — bukan berita terkini yang telah diverifikasi.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita & Peristiwa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications show simulated volcano and earthquake history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Notifikasi contoh'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Semua Notifikasi'), findsOneWidget);
    expect(
      find.textContaining('Bukan peringatan bencana real-time'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('notification-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-card-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-card-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-card-3')), findsOneWidget);
    expect(find.text('CONTOH PERINGATAN GUNUNG API'), findsOneWidget);
    expect(find.text('CONTOH INFORMASI GEMPA'), findsOneWidget);
    expect(
      find.text('Sumber yang direncanakan: BMKG · Belum terintegrasi'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi contoh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita & Peristiwa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications fit a desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Notifikasi contoh'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-card-3')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification destinations open relevant pages and return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Notifikasi contoh'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notification-card-1')));
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-card-0')));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Tingkat Aktivitas Gunung Api'), findsOneWidget);
    await tester.tap(find.text('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-card-2')));
    await tester.pumpAndSettle();
    expect(find.text('Laporan Gunung Api - DATA CONTOH'), findsOneWidget);
    expect(find.text('Gunung Marapi'), findsWidgets);
    await tester.tap(find.text('Kembali').first);
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-card-3')));
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);
    expect(
      find.textContaining('Bukan peringatan bencana real-time'),
      findsOneWidget,
    );
    for (var index = 0; index < 4; index++) {
      expect(find.byKey(ValueKey('notification-card-$index')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency contacts open from Menu and call choices are safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('KONTAK DARURAT'));
    await tester.pumpAndSettle();

    expect(find.text('Kontak & Pengaduan'), findsOneWidget);
    expect(find.text('Kontak Darurat'), findsNWidgets(2));
    expect(find.text('Pengaduan'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains(
              'Untuk kondisi yang mengancam keselamatan jiwa',
            ),
      ),
      findsOneWidget,
    );
    for (final id in [
      'bnpb',
      'basarnas',
      'medical',
      'police',
      'fire',
      'integrated',
    ]) {
      expect(find.byKey(ValueKey('emergency-contact-$id')), findsOneWidget);
      expect(find.byKey(ValueKey('call-$id')), findsOneWidget);
    }
    expect(find.text('117'), findsOneWidget);
    expect(find.text('115'), findsOneWidget);
    expect(find.text('118 / 119'), findsOneWidget);
    expect(find.text('110'), findsOneWidget);
    expect(find.text('113'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
    expect(
      find.text('Ketersediaan layanan 112 bergantung pada wilayah.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('call-medical')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih nomor layanan medis'), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
    expect(find.text('119'), findsOneWidget);
    await tester.tap(find.text('119'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency contacts fit a desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('KONTAK DARURAT'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('emergency-contact-integrated')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'complaint tab switches, validates required fields, and simulates submit',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const MyApp());
        await tester.tap(find.text('Menu').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('KONTAK DARURAT'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pengaduan').first);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('complaint-submit')), findsOneWidget);
        expect(find.text('Nama Pelapor'), findsOneWidget);
        expect(find.text('Nomor Telepon'), findsOneWidget);
        expect(find.text('Lokasi Kejadian'), findsOneWidget);
        expect(find.text('Deskripsi Kejadian'), findsOneWidget);
        expect(
          find.text(
            'Simulasi lokal: data dan lampiran tidak dikirim ke server.',
          ),
          findsOneWidget,
        );

        final submit = find.byKey(const ValueKey('complaint-submit'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.textContaining('belum dikirim ke server'), findsNothing);
        expect(tester.takeException(), isNull);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Pelapor Contoh');
        await tester.enterText(fields.at(1), '081234567890');
        await tester.enterText(fields.at(2), 'Padang, Sumatera Barat');
        await tester.enterText(
          fields.at(3),
          'Contoh deskripsi kejadian untuk simulasi.',
        );
        await tester.tap(find.byKey(const ValueKey('complaint-category')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Erupsi gunung api').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.textContaining('belum dikirim ke server'), findsOneWidget);
        expect(find.textContaining('diterima petugas'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Kontak Darurat').first);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('emergency-contact-bnpb')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('mitigation stages switch content and back returns to Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PANDUAN MITIGASI'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Mitigasi'), findsOneWidget);
    expect(find.textContaining('Kenali tanda peringatan'), findsOneWidget);
    for (var step = 1; step <= 8; step++) {
      expect(
        find.byKey(ValueKey('mitigation-step-before-$step')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('mitigation-step-before-9')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Saat Erupsi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tetap tenang'), findsOneWidget);
    for (var step = 1; step <= 8; step++) {
      expect(
        find.byKey(ValueKey('mitigation-step-during-$step')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('mitigation-step-during-9')),
      findsNothing,
    );

    await tester.tap(find.text('Evakuasi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mulai evakuasi'), findsOneWidget);
    for (var step = 1; step <= 8; step++) {
      expect(
        find.byKey(ValueKey('mitigation-step-evacuation-$step')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('mitigation-step-evacuation-9')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pasca\nErupsi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tetap berada di tempat aman'), findsOneWidget);
    for (var step = 1; step <= 8; step++) {
      expect(
        find.byKey(ValueKey('mitigation-step-after-$step')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('mitigation-step-after-9')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mitigation layout fits a desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PANDUAN MITIGASI'));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Mitigasi'), findsOneWidget);
    expect(find.byTooltip('Kembali'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Evakuasi'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mitigation-step-evacuation-8')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mitigation-step-evacuation-9')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pasca\nErupsi'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mitigation-step-after-8')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mitigation-step-after-9')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color foreground, Color background) {
  double luminance(Color color) {
    double channel(double normalized) {
      return normalized <= .04045
          ? normalized / 12.92
          : math.pow((normalized + .055) / 1.055, 2.4).toDouble();
    }

    return .2126 * channel(color.r) +
        .7152 * channel(color.g) +
        .0722 * channel(color.b);
  }

  final light = luminance(foreground) > luminance(background)
      ? luminance(foreground)
      : luminance(background);
  final dark = luminance(foreground) > luminance(background)
      ? luminance(background)
      : luminance(foreground);
  return (light + .05) / (dark + .05);
}
