import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  testWidgets('contact needs confirmation and cancellation never opens phone', (
    tester,
  ) async {
    final dialed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsCard(
            contacts: const [
              QuickEmergencyContact(
                name: 'BNPB',
                numbers: ['117'],
                source: 'Sumber uji',
                verified: true,
              ),
            ],
            openDialer: (number) async {
              dialed.add(number);
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('home-emergency-BNPB')));
    await tester.pumpAndSettle();
    expect(dialed, isEmpty);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(dialed, isEmpty);
    await tester.tap(find.byKey(const ValueKey('home-emergency-BNPB')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Telepon 117'));
    await tester.pumpAndSettle();
    expect(dialed, ['117']);
  });

  testWidgets('unverified contact cannot open a dialer', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsCard(
            contacts: const [
              QuickEmergencyContact(
                name: 'Belum diperiksa',
                numbers: ['117'],
                source: '',
                verified: false,
              ),
            ],
            openDialer: (_) async {
              opened = true;
            },
          ),
        ),
      ),
    );
    final button = tester.widget<InkWell>(
      find.byKey(const ValueKey('home-emergency-Belum diperiksa')),
    );
    expect(button.onTap, isNull);
    expect(opened, isFalse);
  });
}
