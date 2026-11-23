import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';

// Bundled emergency contacts remain available offline; sources are per contact.
const _nationalContacts = <EmergencyContact>[
  EmergencyContact(
    id: 'bnpb',
    name: 'Badan Nasional Penanggulangan Bencana',
    organization: 'BNPB',
    displayNumber: '117',
    dialNumbers: ['117'],
    icon: Icons.apartment_rounded,
    numberVerified: true,
    sourceTitle: 'BNPB menyediakan Call Center 117',
    sourceOrganization: 'BNPB',
    sourceUrl: 'https://www.bnpb.go.id/berita/jelang-libur-idul-fitri-2026-bnpb-tingkatkan-kesiapsiagaan-hadapi-bencana',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContact(
    id: 'basarnas',
    name: 'Badan Nasional Pencarian dan Pertolongan',
    organization: 'Basarnas',
    displayNumber: '115',
    dialNumbers: ['115'],
    icon: Icons.search_rounded,
    numberVerified: true,
    sourceTitle: 'Kontak Darurat SAR',
    sourceOrganization: 'BASARNAS',
    sourceUrl: 'https://basarnas.go.id/',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContact(
    id: 'medical',
    name: 'Darurat Medis / Ambulans',
    organization: 'Layanan medis',
    displayNumber: '118 / 119',
    dialNumbers: ['118', '119'],
    icon: Icons.medical_services_rounded,
    numberVerified: true,
    sourceTitle: 'Buku Saku Menghadapi Bencana',
    sourceOrganization: 'BNPB',
    sourceUrl: 'https://bnpb.go.id/storage/app/media/Buku%20BNPB/Buku%20Saku%20Bencana%20BNPB.pdf',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContact(
    id: 'police',
    name: 'Kepolisian Republik Indonesia',
    organization: 'Polri',
    displayNumber: '110',
    dialNumbers: ['110'],
    icon: Icons.local_police_rounded,
    numberVerified: true,
    sourceTitle: 'Call Center 110',
    sourceOrganization: 'Polri',
    sourceUrl: 'https://polri.go.id/kontak/call-center-110',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContact(
    id: 'fire',
    name: 'Pemadam Kebakaran',
    organization: 'Damkar',
    displayNumber: '113',
    dialNumbers: ['113'],
    icon: Icons.local_fire_department_rounded,
    numberVerified: true,
    sourceTitle: 'Buku Saku Menghadapi Bencana',
    sourceOrganization: 'BNPB',
    sourceUrl: 'https://bnpb.go.id/storage/app/media/Buku%20BNPB/Buku%20Saku%20Bencana%20BNPB.pdf',
    sourceAccessedAt: '23 Oktober 2026',
  ),
  EmergencyContact(
    id: 'integrated',
    name: 'Layanan Darurat Terpadu',
    organization: 'Darurat',
    displayNumber: '112',
    dialNumbers: ['112'],
    icon: Icons.emergency_rounded,
    numberVerified: true,
    sourceTitle: 'Tentang Layanan Panggilan Darurat 112',
    sourceOrganization: 'Kementerian Komunikasi dan Digital',
    sourceUrl: 'https://layanan112.komdigi.go.id/tentang',
    sourceAccessedAt: '23 Oktober 2026',
    note: 'Ketersediaan layanan 112 bergantung pada wilayah.',
  ),
];

const complaintCategories = <String>[
  'Erupsi gunung api',
  'Gempa bumi',
  'Banjir',
  'Tsunami',
  'Lainnya',
];

final padangContactRegion = ValueNotifier<bool>(false);

void updateContactRegion(String? city, String? province) {
  final name = city?.trim().toLowerCase();
  padangContactRegion.value =
      (name == 'padang' || name == 'kota padang') &&
      province?.trim().toLowerCase() == 'sumatera barat';
}

List<EmergencyContact> get sampleEmergencyContacts =>
    padangContactRegion.value ? _padangContacts : _nationalContacts;
const _padangContacts = <EmergencyContact>[
  EmergencyContact(
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
  EmergencyContact(
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
  EmergencyContact(
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
