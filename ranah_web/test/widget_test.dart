import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/main.dart';
import 'package:ranah_web/pages/emergency_contacts_page.dart';
import 'package:ranah_web/pages/admin_login_page.dart';
import 'package:ranah_web/pages/admin_panel_page.dart';
import 'package:ranah_web/theme/ranah_theme.dart';
import 'package:ranah_web/widgets/ranah_header.dart';

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
      await _pumpReadyApp(tester);
      for (final destination in ['home', 'map', 'voice', 'news', 'menu']) {
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

  testWidgets('header navigation fits supported and collapsed widths', (
    tester,
  ) async {
    const sizes = [
      Size(320, 720),
      Size(375, 800),
      Size(768, 800),
      Size(1280, 900),
      Size(1440, 900),
      // Four equal bottom-navigation items receive 0.4 dp each at this width.
      Size(1.6, 720),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in sizes) {
      final collapsed = size.width < 2;
      tester.view.physicalSize = collapsed ? const Size(2, 900) : size;
      tester.view.devicePixelRatio = collapsed ? 1.25 : 1;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Column(
                children: [
                  RanahHeader(
                    selected: RanahDestination.home,
                    onSelect: (_) {},
                    onNotifications: () {},
                  ),
                  const Expanded(child: SizedBox()),
                  if (size.width < 600)
                    RanahBottomNavigation(
                      selected: RanahDestination.home,
                      onSelect: (_) {},
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
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
    'activity page does not substitute local examples when API is unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpReadyApp(tester);
      await tester.tap(find.text('Peta').first);
      await tester.pumpAndSettle();
      expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);

      final activityAction = find.text('Laporan Aktivitas Gunung');
      await tester.ensureVisible(activityAction);
      await tester.tap(activityAction);
      await tester.pumpAndSettle();
      expect(find.text('Aktivitas Gunung Api'), findsOneWidget);

      expect(
        find.textContaining('Daftar gunung belum dapat dimuat'),
        findsOneWidget,
      );
      expect(find.text('Gunung Semeru'), findsNothing);
      expect(find.text('Gunung Marapi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'news does not substitute local examples when API is unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpReadyApp(tester);
      await tester.tap(find.text('Berita').first);
      await tester.pumpAndSettle();
      expect(find.text('Berita dan Event'), findsOneWidget);
      expect(find.textContaining('Berita belum dapat dimuat'), findsOneWidget);
      expect(find.textContaining('Contoh Berita:'), findsNothing);
      expect(find.textContaining('CONTOH'), findsNothing);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('news error state fits a desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);
    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(find.textContaining('Berita belum dapat dimuat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications require the Laravel feed and offer retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpReadyApp(tester);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Notifikasi BMKG · Sumatera Barat'), findsOneWidget);
    expect(find.text('Notifikasi BMKG belum dapat dimuat.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.textContaining('DATA SIMULASI'), findsNothing);
    expect(find.byKey(const ValueKey('notification-card-0')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita Utama'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live notifications error state fits a desktop viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpReadyApp(tester);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi BMKG belum dapat dimuat.'), findsOneWidget);
    expect(find.textContaining('DATA SIMULASI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live notifications do not expose sample destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpReadyApp(tester);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi BMKG belum dapat dimuat.'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-card-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency contacts open from Menu and call choices are safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpReadyApp(tester);
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

    await _pumpReadyApp(tester);
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
    'complaint tab validates fields and requires consent before submitting',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: EmergencyContactsPage(onBack: () {})),
          ),
        );

        await tester.tap(find.text('Pengaduan').first);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('complaint-submit')), findsOneWidget);
        expect(find.text('Nama Pelapor'), findsOneWidget);
        expect(find.text('Nomor Telepon'), findsOneWidget);
        expect(find.text('Lokasi Kejadian'), findsOneWidget);
        expect(find.text('Deskripsi Kejadian'), findsOneWidget);
        expect(find.textContaining('Simulasi lokal'), findsNothing);

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
        final category = find.byKey(const ValueKey('complaint-category'));
        await tester.ensureVisible(category);
        await tester.tap(category);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Erupsi gunung api').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text('Persetujuan diperlukan sebelum mengirim.'),
          findsOneWidget,
        );
        expect(find.textContaining('diterima petugas'), findsNothing);
        expect(tester.takeException(), isNull);

        final contactsTab = find.text('Kontak Darurat').first;
        await tester.ensureVisible(contactsTab);
        await tester.tap(contactsTab);
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

    await _pumpReadyApp(tester);
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

    await _pumpReadyApp(tester);
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

Future<void> _pumpReadyApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
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
