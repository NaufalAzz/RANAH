import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';

// Nomor mengikuti BRD. BNPB 117 belum terverifikasi ulang dan tidak dapat didial.
const sampleEmergencyContacts = <EmergencyContact>[
  EmergencyContact(
    id: 'bnpb',
    name: 'Badan Nasional Penanggulangan Bencana',
    organization: 'BNPB',
    displayNumber: '117',
    dialNumbers: [],
    icon: Icons.apartment_rounded,
    numberVerified: false,
    note: 'Nomor acuan BRD; perlu verifikasi sebelum digunakan.',
  ),
  EmergencyContact(
    id: 'basarnas',
    name: 'Badan Nasional Pencarian dan Pertolongan',
    organization: 'Basarnas',
    displayNumber: '115',
    dialNumbers: ['115'],
    icon: Icons.search_rounded,
    numberVerified: true,
  ),
  EmergencyContact(
    id: 'medical',
    name: 'Darurat Medis / Ambulans',
    organization: 'Layanan medis',
    displayNumber: '118 / 119',
    dialNumbers: ['118', '119'],
    icon: Icons.medical_services_rounded,
    numberVerified: true,
  ),
  EmergencyContact(
    id: 'police',
    name: 'Kepolisian Republik Indonesia',
    organization: 'Polri',
    displayNumber: '110',
    dialNumbers: ['110'],
    icon: Icons.local_police_rounded,
    numberVerified: true,
  ),
  EmergencyContact(
    id: 'fire',
    name: 'Pemadam Kebakaran',
    organization: 'Damkar',
    displayNumber: '113',
    dialNumbers: ['113'],
    icon: Icons.local_fire_department_rounded,
    numberVerified: true,
  ),
  EmergencyContact(
    id: 'integrated',
    name: 'Layanan Darurat Terpadu',
    organization: 'Darurat',
    displayNumber: '112',
    dialNumbers: ['112'],
    icon: Icons.emergency_rounded,
    numberVerified: true,
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
