import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  const marapi = SiagaGuide(
    id: 1,
    name: 'Marapi',
    status: 'Level II (Waspada)',
    recommendation: 'Ikuti arahan PVMBG.',
    period: '23 November 2026',
    retrievedAt: null,
  );
  const krb = EruptionKrbFeature(
    volcanoName: 'Marapi',
    zone: 'KRB II',
    mapYear: 2010,
  );

  test('outside polygons does not claim absolute safety', () {
    final result = assessEruptionLocation(
      spatialStatus: 'no_data',
      features: const [],
      reports: const [],
      accuracyMeters: 20,
    );
    expect(result.kind, EruptionAssessmentKind.noIntersection);
    expect(result.showRecommendation, isFalse);
    expect(result.reason, contains('bukan jaminan'));
  });

  test(
    'Level I inside KRB reports normal activity but preserves KRB caution',
    () {
      final result = assessEruptionLocation(
        spatialStatus: 'hasil_tersedia',
        features: const [krb],
        reports: const [
          SiagaGuide(
            id: 1,
            name: 'Marapi',
            status: 'Level I (Normal)',
            recommendation: null,
            period: '',
            retrievedAt: null,
          ),
        ],
        accuracyMeters: 20,
      );
      expect(result.kind, EruptionAssessmentKind.normalInKrb);
      expect(result.showRecommendation, isFalse);
      expect(result.reason, contains('KRB tetap'));
    },
  );

  test('raised level inside matching KRB shows official recommendation', () {
    final result = assessEruptionLocation(
      spatialStatus: 'hasil_tersedia',
      features: const [krb],
      reports: const [marapi],
      accuracyMeters: 20,
    );
    expect(result.kind, EruptionAssessmentKind.monitor);
    expect(result.guide?.name, 'Marapi');
    expect(result.showRecommendation, isTrue);
  });

  test('missing status, unverified coverage and poor GPS are unknown', () {
    for (final result in [
      assessEruptionLocation(
        spatialStatus: 'hasil_tersedia',
        features: const [krb],
        reports: const [],
        accuracyMeters: 20,
      ),
      assessEruptionLocation(
        spatialStatus: 'di_luar_cakupan_layer',
        features: const [],
        reports: const [],
        accuracyMeters: 20,
      ),
      assessEruptionLocation(
        spatialStatus: 'hasil_tersedia',
        features: const [krb],
        reports: const [marapi],
        accuracyMeters: 1500,
      ),
    ]) {
      expect(result.kind, EruptionAssessmentKind.unknown);
      expect(result.showRecommendation, isFalse);
    }
  });

  test('marker colors map activity levels and keep unknown distinct', () {
    expect(
      eruptionActivityColor('Level I (Normal)'),
      isNot(eruptionActivityColor('Level II (Waspada)')),
    );
    expect(
      eruptionActivityColor('Level II (Waspada)'),
      isNot(eruptionActivityColor('Level III (Siaga)')),
    );
    expect(
      eruptionActivityColor('Level III (Siaga)'),
      isNot(eruptionActivityColor('Level IV (Awas)')),
    );
    expect(
      eruptionActivityColor(null),
      isNot(eruptionActivityColor('Level I')),
    );
  });

  test('old activity report cannot be used to announce a current level', () {
    final result = assessEruptionLocation(
      spatialStatus: 'hasil_tersedia',
      features: const [krb],
      reports: [
        SiagaGuide(
          id: 1,
          name: 'Marapi',
          status: 'Level II (Waspada)',
          recommendation: 'Lama',
          period: '',
          retrievedAt: DateTime(2020),
        ),
      ],
      accuracyMeters: 20,
    );
    expect(result.kind, EruptionAssessmentKind.unknown);
    expect(result.reason, contains('lebih dari tujuh hari'));
  });

  testWidgets('map card hides volcano recommendation outside known KRB', (
    tester,
  ) async {
    final assessment = assessEruptionLocation(
      spatialStatus: 'no_data',
      features: const [],
      reports: const [],
      accuracyMeters: 20,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SiagaMapCard(
            volcanoName: 'Marapi',
            assessment: assessment,
            guide: marapi,
            onOpenGuide: () {},
          ),
        ),
      ),
    );
    expect(
      find.text('Tidak ditemukan irisan KRB pada titik ini'),
      findsOneWidget,
    );
    expect(find.textContaining('Ikuti arahan PVMBG'), findsNothing);
    expect(find.text('Lihat Alasan dan Data'), findsOneWidget);
  });
}
