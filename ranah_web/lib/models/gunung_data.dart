class GunungRecord {
  const GunungRecord({
    required this.id,
    required this.nama,
    this.provinsi,
    this.kabupaten,
    this.statusAktivitas,
    this.sumberData,
    this.waktuPengambilan,
    this.latitude,
    this.longitude,
    this.statusValidasiKoordinat,
    this.sumberKoordinat,
    this.sumberKoordinatId,
  });

  final int id;
  final String nama;
  final String? provinsi;
  final String? kabupaten;
  final String? statusAktivitas;
  final String? sumberData;
  final DateTime? waktuPengambilan;
  final double? latitude;
  final double? longitude;
  final String? statusValidasiKoordinat;
  final String? sumberKoordinat;
  final String? sumberKoordinatId;

  int? get activityLevel {
    final match = RegExp(
      r'^\s*Level\s+(IV|III|II|I)\b',
      caseSensitive: false,
    ).firstMatch(statusAktivitas ?? '');
    return switch (match?.group(1)?.toUpperCase()) {
      'I' => 1,
      'II' => 2,
      'III' => 3,
      'IV' => 4,
      _ => null,
    };
  }

  factory GunungRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final nama = _text(json['nama']);
    if (id == null || nama == null) {
      throw const FormatException('Record gunung tidak memiliki ID atau nama.');
    }

    return GunungRecord(
      id: id,
      nama: nama,
      provinsi: _text(json['provinsi']),
      kabupaten: _text(json['kabupaten']),
      statusAktivitas: _text(json['status_aktivitas']),
      sumberData: _text(json['sumber_data']),
      waktuPengambilan: _date(json['waktu_pengambilan']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      statusValidasiKoordinat: _text(json['status_validasi_koordinat']),
      sumberKoordinat: _text(json['sumber_koordinat']),
      sumberKoordinatId: _text(json['sumber_koordinat_id']),
    );
  }
}

class GunungReportRecord {
  const GunungReportRecord({
    required this.id,
    required this.gunungId,
    this.periodeMulai,
    this.periodeSelesai,
    this.periodeWaktu,
    this.dataKlimatologi,
    this.pengamatanVisual,
    this.rekomendasi,
    this.foto,
    this.sumber,
    this.waktuPublikasi,
    this.waktuPengambilan,
    this.urlSumber,
    this.sumberId,
  });

  final int id;
  final int? gunungId;
  final String? periodeMulai;
  final String? periodeSelesai;
  final String? periodeWaktu;
  final String? dataKlimatologi;
  final String? pengamatanVisual;
  final String? rekomendasi;
  final String? foto;
  final String? sumber;
  final DateTime? waktuPublikasi;
  final DateTime? waktuPengambilan;
  final String? urlSumber;
  final String? sumberId;

  factory GunungReportRecord.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final rawGunungId = json['gunung_id'];
    final gunungId = rawGunungId is int
        ? rawGunungId
        : int.tryParse(rawGunungId?.toString() ?? '');
    if (id == null) {
      throw const FormatException('Record laporan gunung tidak memiliki ID.');
    }

    return GunungReportRecord(
      id: id,
      gunungId: gunungId,
      periodeMulai: _text(json['periode_mulai']),
      periodeSelesai: _text(json['periode_selesai']),
      periodeWaktu: _text(json['periode_waktu']),
      dataKlimatologi: _text(json['data_klimatologi']),
      pengamatanVisual: _text(json['pengamatan_visual']),
      rekomendasi: _text(json['rekomendasi']),
      foto: _text(json['foto']),
      sumber: _text(json['sumber']),
      waktuPublikasi: _date(json['waktu_publikasi']),
      waktuPengambilan: _date(json['waktu_pengambilan']),
      urlSumber: _text(json['url_sumber']),
      sumberId: _text(json['sumber_id']),
    );
  }
}

class GunungDetailRecord {
  const GunungDetailRecord({required this.gunung, required this.laporan});

  final GunungRecord gunung;
  final List<GunungReportRecord> laporan;

  factory GunungDetailRecord.fromJson(Map<String, dynamic> json) {
    final rawGunung = json['gunung'];
    final rawReports = json['laporan'];
    if (rawGunung is! Map || rawReports is! List) {
      throw const FormatException('Bentuk detail gunung tidak sesuai kontrak.');
    }

    final gunung = GunungRecord.fromJson(Map<String, dynamic>.from(rawGunung));
    final reports = <GunungReportRecord>[];
    for (final rawReport in rawReports) {
      if (rawReport is! Map) {
        throw const FormatException('Item laporan gunung bukan objek JSON.');
      }
      final report = GunungReportRecord.fromJson(
        Map<String, dynamic>.from(rawReport),
      );
      if (report.gunungId != null && report.gunungId != gunung.id) {
        throw const FormatException('Laporan tidak terkait dengan gunung ini.');
      }
      reports.add(report);
    }

    reports.sort((a, b) {
      final aPublished = a.waktuPublikasi;
      final bPublished = b.waktuPublikasi;
      if (aPublished == null && bPublished != null) return 1;
      if (aPublished != null && bPublished == null) return -1;
      if (aPublished != null && bPublished != null) {
        final byPublication = bPublished.compareTo(aPublished);
        if (byPublication != 0) return byPublication;
      }
      return b.id.compareTo(a.id);
    });

    return GunungDetailRecord(
      gunung: gunung,
      laporan: List.unmodifiable(reports),
    );
  }
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) => DateTime.tryParse(_text(value) ?? '');

double? _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
