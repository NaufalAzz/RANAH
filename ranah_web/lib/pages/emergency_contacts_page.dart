import 'package:flutter/material.dart';

import '../data/emergency_contacts.dart';
import '../services/complaint_repository.dart';
import '../theme/ranah_theme.dart';
import '../utils/emergency_call.dart';
import '../utils/complaint_file_picker.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';

const _complaintCategories = [
  'Erupsi gunung api',
  'Gempa bumi',
  'Banjir',
  'Tsunami',
  'Lainnya',
];

typedef ComplaintFilePicker = Future<List<ComplaintAttachment>> Function();

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({
    required this.onBack,
    this.complaintRepository,
    this.filePicker,
    super.key,
  });

  final VoidCallback onBack;
  final ComplaintRepository? complaintRepository;
  final ComplaintFilePicker? filePicker;

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final ComplaintRepository _complaintRepository;
  late final bool _ownsComplaintRepository;
  String? _selectedCategory;
  List<ComplaintAttachment> _selectedFiles = [];
  bool _showComplaint = false;
  bool _consented = false;
  bool _isSubmitting = false;
  bool _consentError = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _ownsComplaintRepository = widget.complaintRepository == null;
    _complaintRepository = widget.complaintRepository ?? ComplaintRepository();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    if (_ownsComplaintRepository) _complaintRepository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : constraints.maxWidth;
      final horizontal = width < 600 ? 20.0 : 34.0;
      return RanahPageScrollLayout(
        maxContentWidth: width,
        title: _ContactsBanner(maxContentWidth: width),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                RanahSpacing.md,
                horizontal,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RanahBackButton(onPressed: widget.onBack),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                RanahSpacing.md,
                horizontal,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ContactTab(
                      selected: !_showComplaint,
                      onTap: () => setState(() => _showComplaint = false),
                    ),
                  ),
                  SizedBox(width: RanahSpacing.md),
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
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.lg,
                  horizontal,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
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
                      isSubmitting: _isSubmitting,
                      consented: _consented,
                      consentError: _consentError,
                      onConsentChanged: (value) => setState(() {
                        _consented = value;
                        _consentError = false;
                      }),
                      submissionError: _submissionError,
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.md,
                  horizontal,
                  0,
                ),
                child: const _EmergencyNotice(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.md,
                  horizontal,
                  RanahSpacing.sm,
                ),
                child: const Text(
                  'Kontak Darurat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                    index == emergencyContacts.length - 1 ? 0 : RanahSpacing.sm,
                  ),
                  child: _EmergencyContactCard(
                    contact: emergencyContacts[index],
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );

  Future<void> _pickFiles() async {
    try {
      final files = await (widget.filePicker ?? pickComplaintFiles)();
      if (mounted && files.isNotEmpty) {
        setState(() {
          _selectedFiles = files;
          _submissionError = null;
        });
      }
    } on ComplaintSubmissionException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Foto tidak dapat dibaca. Silakan pilih kembali.');
    }
  }

  Future<void> _submitComplaint() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    if (!_consented) {
      setState(() => _consentError = true);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
      _consentError = false;
    });
    try {
      final receipt = await _complaintRepository.submit(
        reporterName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        consented: _consented,
        attachments: _selectedFiles,
      );
      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _phoneController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _selectedFiles = [];
        _selectedCategory = null;
        _consented = false;
      });
      _showMessage(
        'Server menerima pengaduan #${receipt.id} pada '
        '${_formatReceivedAt(receipt.receivedAt)}. Ini belum berarti laporan telah ditangani.',
      );
    } on ComplaintSubmissionException catch (error) {
      if (!mounted) return;
      final fieldMessages = error.fieldErrors.entries
          .map((entry) => '${_fieldLabel(entry.key)}: ${entry.value}')
          .join('\n');
      setState(() {
        _submissionError = fieldMessages.isEmpty
            ? error.message
            : '${error.message}\n$fieldMessages';
      });
      _showMessage(_submissionError!);
    } catch (_) {
      if (!mounted) return;
      const message =
          'Pengiriman gagal atau belum terkonfirmasi. Isian tetap tersimpan; periksa status sebelum mencoba lagi.';
      setState(() => _submissionError = message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _fieldLabel(String key) => switch (key.split('.').first) {
    'nama_pelapor' => 'Nama pelapor',
    'nomor_telepon' => 'Nomor telepon',
    'kategori' => 'Kategori',
    'lokasi_kejadian' => 'Lokasi',
    'deskripsi' => 'Deskripsi',
    'persetujuan' => 'Persetujuan',
    'media' => 'Lampiran',
    _ => 'Isian',
  };

  String _formatReceivedAt(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _ContactsBanner extends StatelessWidget {
  const _ContactsBanner({required this.maxContentWidth});

  final double maxContentWidth;

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: RanahColors.banner,
    maxContentWidth: maxContentWidth,
    child: Container(
      constraints: const BoxConstraints(
        minHeight: RanahPageHeaderStyle.minHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RanahPageHeaderStyle.horizontalPadding,
        vertical: RanahPageHeaderStyle.verticalPadding,
      ),
      color: RanahColors.banner,
      child: Row(
        children: [
          const Icon(
            Icons.phone_in_talk_outlined,
            size: RanahPageHeaderStyle.iconSize,
          ),
          const SizedBox(width: RanahPageHeaderStyle.iconGap),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.kicker,
                ),
                Text(
                  'Kontak & Pengaduan',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.title,
                ),
                Text(
                  'Hubungi kami atau kirim laporan',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
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
    borderRadius: BorderRadius.circular(RanahRadii.md),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RanahRadii.md),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Kontak Darurat',
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9C3CE),
              fontSize: 12,
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
    borderRadius: BorderRadius.circular(RanahRadii.md),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RanahRadii.md),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Pengaduan',
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9C3CE),
              fontSize: 12,
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
      borderRadius: BorderRadius.circular(RanahRadii.sm),
    ),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
        children: [
          TextSpan(
            text: 'Catatan: ',
            style: TextStyle(
              color: Color(0xFFFFB3B5),
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
      borderRadius: BorderRadius.circular(RanahRadii.sm),
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
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                contact.organization,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFB0BAC8),
                  fontSize: 12,
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
                    fontSize: 12,
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
            style: TextStyle(color: Color(0xFFFF8585), fontSize: 12),
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
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(
        fontSize: 12,
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
    required this.isSubmitting,
    required this.consented,
    required this.consentError,
    required this.onConsentChanged,
    required this.submissionError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<ComplaintAttachment> selectedFiles;
  final VoidCallback onPickFiles;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final bool consented;
  final bool consentError;
  final ValueChanged<bool> onConsentChanged;
  final String? submissionError;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth >= 760
                ? (constraints.maxWidth - RanahSpacing.md) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: RanahSpacing.md,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Nama Pelapor'),
                      _textField(
                        nameController,
                        hint: 'Masukkan nama pelapor',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Nomor Telepon'),
                      _textField(
                        phoneController,
                        hint: 'Masukkan nomor telepon yang dapat dihubungi',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          final digits = text.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 8) {
                            return 'Nomor telepon wajib diisi';
                          }
                          if (text.length > 30 ||
                              !RegExp(r'^[0-9+\s().-]+$').hasMatch(text)) {
                            return 'Masukkan nomor telepon yang valid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Pilih Kategori'),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('complaint-category'),
                        initialValue: selectedCategory,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF26394D),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: _fieldDecoration(
                          'Pilih kategori pengaduan',
                        ),
                        items: [
                          for (final category in _complaintCategories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                        ],
                        onChanged: onCategoryChanged,
                        validator: (value) => value == null
                            ? 'Kategori wajib dipilih'
                            : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Lokasi Kejadian'),
                      _textField(
                        locationController,
                        hint: 'Masukkan lokasi kejadian',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        _label('Foto Kejadian'),
        OutlinedButton.icon(
          key: const ValueKey('complaint-pick-files'),
          onPressed: isSubmitting ? null : onPickFiles,
          icon: const Icon(Icons.attach_file, size: 16),
          label: const Text('Pilih Foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Color(0xFF687B91)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RanahRadii.sm),
            ),
          ),
        ),
        if (selectedFiles.isNotEmpty) ...[
          const SizedBox(height: RanahSpacing.sm),
          Text(
            selectedFiles.map((file) => file.name).join(', '),
            style: const TextStyle(color: Color(0xFFCFD7E2), fontSize: 12),
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
        const SizedBox(height: RanahSpacing.sm),
        CheckboxListTile(
          key: const ValueKey('complaint-consent'),
          value: consented,
          onChanged: isSubmitting
              ? null
              : (value) => onConsentChanged(value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Saya setuju data pengaduan dan foto yang dipilih dikirim ke server untuk dicatat.',
            style: TextStyle(color: Color(0xFFD5DDE7), fontSize: 12),
          ),
        ),
        if (consentError)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'Persetujuan diperlukan sebelum mengirim.',
              style: TextStyle(color: Color(0xFFFF8585), fontSize: 12),
            ),
          ),
        if (submissionError != null) ...[
          const SizedBox(height: RanahSpacing.sm),
          Text(
            submissionError!,
            key: const ValueKey('complaint-submit-error'),
            style: const TextStyle(color: Color(0xFFFFA6A6), fontSize: 12),
          ),
        ],
        const SizedBox(height: RanahSpacing.lg),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const ValueKey('complaint-submit'),
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: RanahColors.eruption,
              foregroundColor: Colors.white,
              disabledBackgroundColor: RanahColors.muted,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RanahRadii.sm),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'KIRIM LAPORAN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(
      top: RanahSpacing.md,
      bottom: RanahSpacing.xs,
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
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
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: _fieldDecoration(hint),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCFD7E2), fontSize: 12),
    filled: true,
    fillColor: const Color(0xFF304358),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: RanahSpacing.md,
      vertical: RanahSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      borderSide: const BorderSide(color: Color(0xFF8AA6BF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      borderSide: const BorderSide(color: Color(0xFF8AA6BF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      borderSide: const BorderSide(color: Color(0xFFD5E2ED), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      borderSide: const BorderSide(color: Color(0xFFFFB3B5)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      borderSide: const BorderSide(color: Color(0xFFFFB3B5), width: 2),
    ),
    errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFFFB3B5)),
  );
}
