import 'package:flutter/material.dart';

import '../data/emergency_contacts.dart';
import '../theme/ranah_theme.dart';
import '../utils/emergency_call.dart';
import '../utils/complaint_file_picker.dart';

const _complaintCategories = [
  'Erupsi gunung api',
  'Gempa bumi',
  'Banjir',
  'Tsunami',
  'Lainnya',
];

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  List<String> _selectedFiles = [];
  bool _showComplaint = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 1000 ? 1000.0 : constraints.maxWidth;
      final horizontal = width < 600 ? 20.0 : 34.0;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ContactsBanner(onBack: widget.onBack),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ContactTab(
                          selected: !_showComplaint,
                          onTap: () => setState(() => _showComplaint = false),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _ComplaintTab(
                          selected: _showComplaint,
                          onTap: () => setState(() => _showComplaint = true),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showComplaint)
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 15, horizontal, 0),
                    child: _ComplaintForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      phoneController: _phoneController,
                      locationController: _locationController,
                      descriptionController: _descriptionController,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      selectedFiles: _selectedFiles,
                      onPickFiles: _pickFiles,
                      onSubmit: _submitComplaint,
                    ),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                    child: const _EmergencyNotice(),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 7),
                    child: const Text(
                      'Kontak Darurat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (var index = 0; index < emergencyContacts.length; index++)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        0,
                        horizontal,
                        index == emergencyContacts.length - 1 ? 0 : 8,
                      ),
                      child: _EmergencyContactCard(
                        contact: emergencyContacts[index],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _pickFiles() async {
    final files = await pickComplaintFiles();
    if (files.isNotEmpty && mounted) {
      setState(() => _selectedFiles = files);
    }
  }

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Simulasi: formulir disiapkan di browser dan belum dikirim ke server atau diterima petugas.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
  }
}

class _ContactsBanner extends StatelessWidget {
  const _ContactsBanner({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.only(left: 12, right: 6),
    color: RanahColors.banner,
    child: Row(
      children: [
        const Icon(Icons.phone_in_talk_outlined, size: 26),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISASTER EVACUATION',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF91A8D0),
                  fontSize: 8,
                  letterSpacing: .45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Kontak & Pengaduan',
                maxLines: 1,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                'Hubungi kami atau kirim laporan',
                maxLines: 1,
                style: TextStyle(color: Color(0xFFC1C8D7), fontSize: 8),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onBack,
          tooltip: 'Kembali',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 34, height: 38),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, size: 17),
        ),
      ],
    ),
  );
}

class _ContactTab extends StatelessWidget {
  const _ContactTab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF21005E) : const Color(0xFF3B5067),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 34,
        child: Center(
          child: Text(
            'Kontak Darurat',
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9C3CE),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ComplaintTab extends StatelessWidget {
  const _ComplaintTab({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF21005E) : const Color(0xFF3B5067),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 34,
        child: Center(
          child: Text(
            'Pengaduan',
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9C3CE),
              fontSize: 9,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmergencyNotice extends StatelessWidget {
  const _EmergencyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF66384C),
      borderRadius: BorderRadius.circular(6),
    ),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.white, fontSize: 9, height: 1.3),
        children: [
          TextSpan(
            text: 'Catatan: ',
            style: TextStyle(
              color: Color(0xFFFF5960),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Untuk kondisi yang mengancam keselamatan jiwa dan membutuhkan pertolongan segera, gunakan Kontak Darurat. Jangan menunggu laporan melalui formulir diproses.',
          ),
        ],
      ),
    ),
  );
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.contact});

  final EmergencyContactSample contact;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('emergency-contact-${contact.id}'),
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF552435), Color(0xFF49213A)],
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0x66E92C2D), width: .7),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: RanahColors.eruption,
            shape: BoxShape.circle,
          ),
          child: Icon(contact.icon, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                contact.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                contact.organization,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFB0BAC8),
                  fontSize: 8,
                  height: 1.2,
                ),
              ),
              Tooltip(
                message:
                    '${contact.sourceTitle} · ${contact.sourceOrganization}\n'
                    '${contact.sourceUrl}\n'
                    'Diakses ${contact.sourceAccessedAt}',
                child: Text(
                  contact.note ??
                      'Nomor diverifikasi · ${contact.sourceAccessedAt}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD0B8C1),
                    fontSize: 7,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        if (contact.numberVerified)
          _PhoneNumberButton(contact: contact)
        else
          const Text(
            'Nomor belum diverifikasi',
            textAlign: TextAlign.right,
            style: TextStyle(color: Color(0xFFFF8585), fontSize: 8),
          ),
      ],
    ),
  );
}

class _PhoneNumberButton extends StatelessWidget {
  const _PhoneNumberButton({required this.contact});

  final EmergencyContactSample contact;

  @override
  Widget build(BuildContext context) => TextButton(
    key: ValueKey('call-${contact.id}'),
    onPressed: () {
      if (contact.dialNumbers.length == 1) {
        callEmergencyNumber(contact.dialNumbers.single);
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pilih nomor layanan medis'),
              ),
              for (final number in contact.dialNumbers)
                ListTile(
                  title: Text(number),
                  leading: const Icon(Icons.call_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    callEmergencyNumber(number);
                  },
                ),
            ],
          ),
        ),
      );
    },
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFFF2025),
      minimumSize: const Size(36, 32),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(
        fontSize: 11,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
      ),
    ),
    child: Text(contact.displayNumber),
  );
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
    required this.selectedFiles,
    required this.onPickFiles,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> selectedFiles;
  final VoidCallback onPickFiles;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Nama Pelapor'),
        _textField(nameController, hint: 'Masukkan nama pelapor'),
        _label('Nomor Telepon'),
        _textField(
          phoneController,
          hint: 'Masukkan nomor telepon yang dapat dihubungi',
          keyboardType: TextInputType.phone,
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            if (digits.isEmpty) return 'Nomor telepon wajib diisi';
            if (digits.length < 8 || digits.length > 15) {
              return 'Masukkan nomor telepon yang valid';
            }
            return null;
          },
        ),
        _label('Pilih Kategori'),
        DropdownButtonFormField<String>(
          key: const ValueKey('complaint-category'),
          initialValue: selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF26394D),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: _fieldDecoration('Pilih kategori pengaduan'),
          items: [
            for (final category in _complaintCategories)
              DropdownMenuItem(value: category, child: Text(category)),
          ],
          onChanged: onCategoryChanged,
          validator: (value) => value == null ? 'Kategori wajib dipilih' : null,
        ),
        _label('Lokasi Kejadian'),
        _textField(locationController, hint: 'Masukkan lokasi kejadian'),
        _label('Foto & Video Kejadian'),
        OutlinedButton.icon(
          key: const ValueKey('complaint-pick-files'),
          onPressed: onPickFiles,
          icon: const Icon(Icons.attach_file, size: 16),
          label: const Text('Pilih Foto atau Video'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: Color(0xFF687B91)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            selectedFiles.join(', '),
            style: const TextStyle(color: Color(0xFFCFD7E2), fontSize: 10),
          ),
        ],
        _label('Deskripsi Kejadian'),
        _textField(
          descriptionController,
          hint: 'Jelaskan kejadian yang dilaporkan',
          maxLines: 5,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Deskripsi kejadian wajib diisi';
            }
            if (value!.trim().length < 10) {
              return 'Deskripsi minimal 10 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            key: const ValueKey('complaint-submit'),
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE42D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'KIRIM LAPORAN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Simulasi lokal: data dan lampiran tidak dikirim ke server.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFCCD4DF), fontSize: 9),
        ),
      ],
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 11, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator:
        validator ??
        (value) =>
            (value ?? '').trim().isEmpty ? 'Kolom ini wajib diisi' : null,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: _fieldDecoration(hint),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9AA8B8), fontSize: 11),
    filled: true,
    fillColor: const Color(0xFF304358),
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF687B91)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF687B91)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFF92A8C0)),
    ),
    errorStyle: const TextStyle(fontSize: 10),
  );
}
