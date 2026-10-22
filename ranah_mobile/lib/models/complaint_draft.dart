class ComplaintDraft {
  const ComplaintDraft({
    required this.reporterName,
    required this.phoneNumber,
    required this.category,
    required this.location,
    required this.description,
    this.attachmentName,
  });

  final String reporterName;
  final String phoneNumber;
  final String category;
  final String location;
  final String description;
  final String? attachmentName;
}
