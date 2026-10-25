import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/sample_emergency_contacts.dart';
import '../models/emergency_contact.dart';
import '../services/api_service.dart';
import '../services/complaint_api.dart';
import '../services/complaint_media_picker.dart';
import '../services/phone_dialer.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

class ContactComplaintPage extends StatefulWidget {
  const ContactComplaintPage({
    required this.onBack,
    this.complaintApi,
    this.mediaPicker,
    super.key,
  });

  final VoidCallback onBack;
  final ComplaintApi? complaintApi;
  final ComplaintMediaPicker? mediaPicker;

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
  late final ComplaintApi _complaintApi;
  late final ComplaintMediaPicker _mediaPicker;

  int _selectedTab = 0;
  int _submissionCount = 0;
  String? _selectedCategory;
  bool _consented = false;
  bool _isSubmitting = false;
  bool _isPickingMedia = false;
  List<XFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _complaintApi = widget.complaintApi ?? ApiService();
    _mediaPicker = widget.mediaPicker ?? GalleryComplaintMediaPicker();
  }

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
            '${contact.displayNumber} belum diverifikasi dan tidak dapat '
            'dibuka melalui aplikasi telepon. ${contact.note ?? ''}',
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
          '${contact.note == null ? '' : '\n\n${contact.note}'}\n\n'
          'Sumber: ${contact.sourceTitle} (${contact.sourceOrganization}), '
          'diakses ${contact.sourceAccessedAt}.\n${contact.sourceUrl}',
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

  Future<void> _submitComplaint() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (!_consented) {
      _showMessage('Setujui pengiriman data untuk melanjutkan.');
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final receipt = await _complaintApi.submitComplaint(
        reporterName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        consented: _consented,
        attachments: _attachments,
      );
      if (!mounted) return;

      setState(() {
        _submissionCount++;
        _nameController.clear();
        _phoneController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _attachments = [];
        _selectedCategory = null;
        _consented = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.darkPanel,
          icon: const Icon(
            Icons.cloud_done_outlined,
            size: 36,
            color: Color(0xFF91D4C8),
          ),
          title: const Text(
            'Pengaduan Berhasil Dikirim',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Server menerima pengaduan. Nomor referensi: '
            '#${receipt.id}. Waktu diterima: ${_formatReceivedAt(receipt.receivedAt)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedOnDark, height: 1.45),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: const BorderSide(color: AppColors.darkPanelBorder),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ComplaintApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '');
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAttachments() async {
    if (_isPickingMedia || _isSubmitting) return;
    setState(() => _isPickingMedia = true);
    try {
      final picked = await _mediaPicker.pickImages();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _attachments = picked.take(3).toList(growable: false);
      });
    } on PlatformException {
      if (mounted) _showMessage('Galeri tidak dapat dibuka. Coba lagi.');
    } catch (_) {
      if (mounted) _showMessage('Foto tidak dapat dipilih. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  void _removeAttachment(XFile file) {
    setState(
      () => _attachments = _attachments
          .where((item) => item.path != file.path)
          .toList(),
    );
  }

  String _formatReceivedAt(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBackground.decoration,
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
                      minimumSize: const Size(0, AppSizes.minimumTapTarget),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              _ContactTabs(
                selectedIndex: _selectedTab,
                onSelected: (index) => setState(() => _selectedTab = index),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('contact-tab-$_selectedTab'),
                    child: _selectedTab == 0
                        ? _EmergencyContactList(onContactTap: _handleContactTap)
                        : _ComplaintForm(
                            formKey: _formKey,
                            nameController: _nameController,
                            phoneController: _phoneController,
                            locationController: _locationController,
                            descriptionController: _descriptionController,
                            attachments: _attachments,
                            onPickAttachments: _pickAttachments,
                            onRemoveAttachment: _removeAttachment,
                            isPickingMedia: _isPickingMedia,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (category) =>
                                setState(() => _selectedCategory = category),
                            consented: _consented,
                            onConsentChanged: (value) =>
                                setState(() => _consented = value),
                            submissionCount: _submissionCount,
                            isSubmitting: _isSubmitting,
                            onSubmit: _submitComplaint,
                          ),
                  ),
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
  Widget build(BuildContext context) => const AppPageBanner(
    icon: Icons.phone_in_talk_rounded,
    eyebrow: 'LAYANAN RANAH',
    title: 'Kontak & Pengaduan',
    subtitle: 'Hubungi kami atau kirim laporan',
    minHeight: 76,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
    iconSize: 37,
    iconGap: AppSpacing.md,
    eyebrowStyle: TextStyle(
      color: AppColors.bannerEyebrow,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
    ),
  );
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
          const SizedBox(width: AppSpacing.xs),
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
          height: AppSizes.minimumTapTarget,
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
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
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
            'Ketuk nomor untuk melihat sumber dan konfirmasi panggilan. '
            'Layanan daerah dapat berbeda ketersediaannya.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
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
              fontSize: 18,
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
    return AppCardSurface(
      variant: AppCardVariant.contact,
      onTap: onTap,
      minimumHeight: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
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
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  contact.note ?? contact.sourceAttribution,
                  style: const TextStyle(
                    color: Color(0xFFB7C8D7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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
    required this.attachments,
    required this.onPickAttachments,
    required this.onRemoveAttachment,
    required this.isPickingMedia,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.consented,
    required this.onConsentChanged,
    required this.submissionCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController descriptionController;
  final List<XFile> attachments;
  final VoidCallback onPickAttachments;
  final ValueChanged<XFile> onRemoveAttachment;
  final bool isPickingMedia;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final bool consented;
  final ValueChanged<bool> onConsentChanged;
  final int submissionCount;
  final bool isSubmitting;
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
                fontSize: 18,
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
              isExpanded: true,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration('Pilih kategori...'),
              items: [
                for (final category in complaintCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
            const _FormLabel(label: 'Foto Kejadian'),
            OutlinedButton.icon(
              onPressed: isPickingMedia ? null : onPickAttachments,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(
                isPickingMedia ? 'Membuka galeri...' : 'Pilih foto dari galeri',
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                backgroundColor: Colors.white,
                disabledForegroundColor: AppColors.muted,
                minimumSize: const Size(0, AppSizes.minimumTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Pilih hingga 3 foto JPG, PNG, atau WebP (maksimal 5 MB per foto).',
                style: TextStyle(color: Color(0xFFD0D9E1), fontSize: 13),
              ),
            ),
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final file in attachments)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image, color: Colors.white70),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    tooltip: 'Hapus foto',
                    onPressed: () => onRemoveAttachment(file),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ),
            ],
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
                'Saya setuju data pengaduan dan foto terpilih dikirim ke server '
                'RANAH untuk pencatatan laporan.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, AppSizes.minimumTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isSubmitting ? 'MENGIRIM...' : 'KIRIM LAPORAN'),
            ),
            const SizedBox(height: 8),
            Text(
              submissionCount == 0
                  ? 'Belum ada pengaduan yang terkirim dari sesi ini.'
                  : 'Berhasil dikirim dari sesi ini: $submissionCount',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD0D9E1), fontSize: 13),
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
          fontSize: 13,
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
    hintStyle: const TextStyle(color: Color(0xFF8995A4), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorStyle: const TextStyle(color: Color(0xFFFFB7B7), fontSize: 13),
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
