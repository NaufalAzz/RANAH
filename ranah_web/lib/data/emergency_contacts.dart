import 'package:flutter/material.dart';

class EmergencyContactSample {
  const EmergencyContactSample({
    required this.id,
    required this.name,
    required this.organization,
    required this.displayNumber,
    required this.dialNumbers,
    required this.icon,
    required this.sourceTitle,
    required this.sourceOrganization,
    required this.sourceUrl,
    required this.sourceAccessedAt,
    this.note,
    this.numberVerified = true,
  });

  final String id;
  final String name;
  final String organization;
  final String displayNumber;
  final List<String> dialNumbers;
  final IconData icon;
  final String sourceTitle;
  final String sourceOrganization;
  final String sourceUrl;
  final String sourceAccessedAt;
  final String? note;
  final bool numberVerified;
}

/// Contact numbers and verification sources mirror the local mobile data.
const _nationalContacts = <EmergencyContactSample>[
  EmergencyContactSample(
    id: 'bnpb',
    name: 'BNPB (Badan Nasional Penanggulangan Bencana)',
    organization: 'BNPB',
    displayNumber: '117',
    dialNumbers: ['117'],
    icon: Icons.apartment_rounded,
    sourceTitle: 'BNPB menyediakan Call Center 117',
    sourceOrganization: 'BNPB',
    sourceUrl: 'https://www.bnpb.go.id/kontak',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContactSample(
    id: 'basarnas',
    name: 'BASARNAS',
    organization: 'SAR',
    displayNumber: '115',
    dialNumbers: ['115'],
    icon: Icons.search_rounded,
    sourceTitle: 'Kontak Darurat SAR',
    sourceOrganization: 'Basarnas',
    sourceUrl: 'https://basarnas.go.id/',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContactSample(
    id: 'medical',
    name: 'Darurat Medis / Ambulans',
    organization: 'Layanan medis',
    displayNumber: '118 / 119',
    dialNumbers: ['118', '119'],
    icon: Icons.medical_services_rounded,
    sourceTitle: 'Buku Saku Menghadapi Bencana',
    sourceOrganization: 'BNPB dan Kementerian Kesehatan',
    sourceUrl: 'https://kemkes.go.id/id/layanan/psc-119',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContactSample(
    id: 'police',
    name: 'Kepolisian Republik Indonesia',
    organization: 'Polri',
    displayNumber: '110',
    dialNumbers: ['110'],
    icon: Icons.local_police_rounded,
    sourceTitle: 'Call Center 110',
    sourceOrganization: 'Polri',
    sourceUrl: 'https://polri.go.id/kontak/call-center-110',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContactSample(
    id: 'fire',
    name: 'Pemadam Kebakaran',
    organization: 'Damkar',
    displayNumber: '113',
    dialNumbers: ['113'],
    icon: Icons.local_fire_department_rounded,
    sourceTitle: 'Buku Saku Menghadapi Bencana',
    sourceOrganization: 'BNPB',
    sourceUrl: 'https://www.bnpb.go.id/storage/app/media/uploads/24/buku-data-bencana/6-buku-saku-cetakan-4-2019.pdf',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContactSample(
    id: 'integrated',
    name: 'Layanan Darurat Terpadu',
    organization: 'Darurat',
    displayNumber: '112',
    dialNumbers: ['112'],
    icon: Icons.emergency_rounded,
    sourceTitle: 'Tentang Layanan Panggilan Darurat 112',
    sourceOrganization: 'Kementerian Komunikasi dan Digital',
    sourceUrl: 'https://layanan112.komdigi.go.id/tentang',
    sourceAccessedAt: '23 Oktober 2026',
    note: 'Ketersediaan layanan 112 bergantung pada wilayah.',
  ),
];

final padangContactRegion = ValueNotifier<bool>(false);

void updateContactRegion(String? city, String? province) {
  final name = city?.trim().toLowerCase();
  padangContactRegion.value =
      (name == 'padang' || name == 'kota padang') &&
      province?.trim().toLowerCase() == 'sumatera barat';
}

List<EmergencyContactSample> get emergencyContacts =>
    padangContactRegion.value ? _padangContacts : _nationalContacts;
const _padangContacts = <EmergencyContactSample>[
  EmergencyContactSample(
    id: 'padang-bpbd',
    name: 'Laporan bencana Kota Padang',
    organization: 'Pusdalops BPBD Kota Padang',
    displayNumber: '0751778775',
    dialNumbers: ['0751778775'],
    icon: Icons.phone_in_talk,
    numberVerified: true,
    sourceTitle: 'Pusdalops BPBD Kota Padang',
    sourceOrganization: 'BPBD Kota Padang',
    sourceUrl: 'https://bpbd.padang.go.id/kontak',
    sourceAccessedAt: '23 November 2026',
  ),
  EmergencyContactSample(
    id: 'padang-pcc',
    name: 'Panggilan darurat terpadu',
    organization: 'Padang Command Center',
    displayNumber: '112',
    dialNumbers: ['112'],
    icon: Icons.phone_in_talk,
    numberVerified: true,
    sourceTitle: 'Padang Command Center',
    sourceOrganization: 'Pemerintah Kota Padang',
    sourceUrl: 'https://sigap.padang.go.id/',
    sourceAccessedAt: '23 November 2026',
  ),
  EmergencyContactSample(
    id: 'padang-psc',
    name: 'Bantuan medis darurat',
    organization: 'PSC 119 Kota Padang',
    displayNumber: '119',
    dialNumbers: ['119'],
    icon: Icons.phone_in_talk,
    numberVerified: true,
    sourceTitle: 'PSC 119 Kota Padang',
    sourceOrganization: 'Dinas Kesehatan Kota Padang',
    sourceUrl: 'https://dinkes.padang.go.id/profil/layanan-pengaduan-warga',
    sourceAccessedAt: '23 November 2026',
  ),
];
