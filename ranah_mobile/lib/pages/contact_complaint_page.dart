import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_emergency_contacts.dart';
import '../models/complaint_draft.dart';
import '../models/emergency_contact.dart';
import '../services/phone_dialer.dart';
import '../theme/app_theme.dart';

class ContactComplaintPage extends StatefulWidget {
  const ContactComplaintPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ContactComplaintPage> createState() => _ContactComplaintPageState();
}

class _ContactComplaintPageState extends State<ContactComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneDialer = PhoneDialer();
  final List<ComplaintDraft> _localSubmissions = [];

  int _selectedTab = 0;
  String? _selectedCategory;
  bool _consented = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleContactTap(EmergencyContact contact) async {
    if (!contact.numberVerified || contact.dialNumbers.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nomor belum terverifikasi'),
          content: Text(
            '${contact.displayNumber} adalah nomor acuan BRD yang belum '
            'diverifikasi ulang. Demi keamanan, nomor ini tidak dapat membuka '
            'aplikasi telepon. ${contact.note ?? ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final selectedNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hubungi ${contact.organization}?'),
        content: Text(
          'Aplikasi Telepon akan dibuka dengan nomor ${contact.displayNumber}. '
          'Periksa ketersediaan layanan di wilayah Anda sebelum menelepon.'
          '${contact.note == null ? '' : '\n\n${contact.note}'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          for (final number in contact.dialNumbers)
            FilledButton(
              onPressed: () => Navigator.pop(context, number),
              child: Text('Buka Telepon $number'),
            ),
        ],
      ),
    );

    if (selectedNumber == null || !mounted) return;
    try {
      await _phoneDialer.openDialer(selectedNumber);
    } on MissingPluginException {
      _showMessage(
        'Aplikasi Telepon hanya dapat dibuka dari perangkat Android.',
      );
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Aplikasi Telepon tidak dapat dibuka.');
    } on ArgumentError {
      _showMessage('Nomor telepon tidak valid.');
    }
  }

  void _submitComplaint() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (!_consented) {
      _showMessage('Setujui penggunaan data untuk melanjutkan simulasi.');
      return;
    }

    setState(() {
      _localSubmissions.add(
        ComplaintDraft(
          reporterName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          category: _selectedCategory!,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
      );
      _nameController.clear();
      _phoneController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _consented = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF123858), Color(0xFF0B2D49)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -130,
            bottom: 18,
            child: _ContactBackgroundRing(),
          ),
          Column(
            children: [
              const _ContactBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('Kembali ke Menu'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              _ContactTabs(
                selectedIndex: _selectedTab,
                onSelected: (index) => setState(() => _selectedTab = index),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _selectedTab == 0
                    ? _EmergencyContactList(onContactTap: _handleContactTap)
                    : _ComplaintForm(
                        formKey: _formKey,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        locationController: _locationController,
                        descriptionController: _descriptionController,
                        selectedCategory: _selectedCategory,
                        onCategoryChanged: (category) =>
                            setState(() => _selectedCategory = category),
                        consented: _consented,
                        onConsentChanged: (value) =>
                            setState(() => _consented = value),
                        submissionCount: _localSubmissions.length,
                        onSubmit: _submitComplaint,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactBanner extends StatelessWidget {
  const _ContactBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF21085F), Color(0xFF100525)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_in_talk_rounded,
            color: Colors.white,
            size: 37,
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'LAYANAN RANAH',
                  style: TextStyle(
                    color: Color(0xFF82C7FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  'Kontak & Pengaduan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Hubungi kami atau kirim laporan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFC8C0D5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTabs extends StatelessWidget {
  const _ContactTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _ContactTabButton(
              label: 'Kontak Darurat',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ContactTabButton(
              label: 'Pengaduan',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTabButton extends StatelessWidget {
  const _ContactTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFF405A73),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFD1D9E2),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactList extends StatelessWidget {
  const _EmergencyContactList({required this.onContactTap});

  final ValueChanged<EmergencyContact> onContactTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF922F41).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
              children: [
                TextSpan(
                  text: 'Catatan: ',
                  style: TextStyle(
                    color: Color(0xFFFF6E72),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Untuk kondisi yang mengancam keselamatan jiwa dan membutuhkan pertolongan segera, gunakan Kontak Darurat. Jangan menunggu laporan melalui formulir diproses.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF922F41).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Ketuk nomor untuk membuka konfirmasi panggilan. Nomor acuan BRD perlu diperiksa kembali; 117 belum dapat dihubungi dari aplikasi.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 13, 4, 8),
          child: Text(
            'Kontak Darurat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final contact in sampleEmergencyContacts) ...[
          _EmergencyContactCard(
            contact: contact,
            onTap: () => onContactTap(contact),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact, required this.onTap});

  final EmergencyContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF702A39).withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB03C4A)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9363D),
                  shape: BoxShape.circle,
                ),
                child: Icon(contact.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      contact.note ?? contact.organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB7C8D7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                contact.displayNumber,
                style: TextStyle(
                  color: contact.numberVerified
                      ? const Color(0xFFFF494F)
                      : const Color(0xFFFFB45C),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintForm extends StatelessWidget {
  const _ComplaintForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.locationController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.consented,
    required this.onConsentChanged,
    required this.submissionCount,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final bool consented;
  final ValueChanged<bool> onConsentChanged;
  final int submissionCount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Pengaduan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 13),
            _FormLabel(label: 'Nama Pelapor'),
            _TextInput(
              controller: nameController,
              hint: 'Masukkan nama lengkap',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama pelapor wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
            _FormLabel(label: 'Nomor Telepon'),
            _TextInput(
              controller: phoneController,
              hint: 'Masukkan nomor telepon',
              keyboardType: TextInputType.phone,
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                return digits.length < 8
                    ? 'Masukkan nomor telepon yang valid.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            const _FormLabel(label: 'Pilih Kategori'),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: _inputDecoration('Pilih kategori...'),
              items: [
                for (final category in complaintCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              validator: (value) =>
                  value == null ? 'Pilih kategori pengaduan.' : null,
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 12),
            _FormLabel(label: 'Lokasi Kejadian'),
            _TextInput(
              controller: locationController,
              hint: 'Masukkan lokasi kejadian',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Lokasi kejadian wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
            const _FormLabel(label: 'Foto & Video Kejadian'),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Lampiran belum tersedia'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                backgroundColor: Colors.white,
                disabledForegroundColor: AppColors.muted,
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Lampiran foto/video belum didukung pada tahap ini.',
                style: TextStyle(color: Color(0xFFD0D9E1), fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
            _FormLabel(label: 'Deskripsi Kejadian'),
            _TextInput(
              controller: descriptionController,
              hint: 'Masukkan deskripsi kejadian dengan lengkap',
              maxLines: 5,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Deskripsi kejadian wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: consented,
              onChanged: (value) => onConsentChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: AppColors.primary,
              title: const Text(
                'Saya setuju data ini digunakan untuk pencatatan pengaduan. Data hanya disimpan sementara di aplikasi ini dan belum dikirim ke server.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('KIRIM LAPORAN'),
            ),
            const SizedBox(height: 8),
            Text(
              submissionCount == 0
                  ? 'Pengaduan belum dikirim ke server.'
                  : 'Tersimpan sementara di sesi aplikasi: $submissionCount',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD0D9E1), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.ink, fontSize: 13),
      decoration: _inputDecoration(hint),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF8995A4), fontSize: 12),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorStyle: const TextStyle(color: Color(0xFFFFB7B7), fontSize: 11),
  );
}

class _ContactBackgroundRing extends StatelessWidget {
  const _ContactBackgroundRing();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.035),
            width: 25,
          ),
        ),
      ),
    );
  }
}
