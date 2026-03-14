import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/submission_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class SubmissionScreen extends StatefulWidget {
  final String assignmentId;

  const SubmissionScreen({super.key, required this.assignmentId});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _urlController = TextEditingController();
  final _submissionService = SubmissionService();
  bool _isLoading = false;

  final List<_PendingAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null && mounted) {
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null) {
            _pendingAttachments.add(_PendingAttachment(
              name: file.name,
              bytes: file.bytes!,
              mimeType: file.extension != null
                  ? _extensionToMime(file.extension!)
                  : null,
              size: file.size,
            ));
          }
        }
      });
    }
  }

  String? _extensionToMime(String ext) {
    return switch (ext.toLowerCase()) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'txt' => 'text/plain',
      'zip' => 'application/zip',
      _ => null,
    };
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    if (url.isEmpty && _pendingAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a file or provide a URL')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final submission = await _submissionService.submitWork(
        assignmentId: widget.assignmentId,
        submissionUrl: url.isEmpty ? null : url,
      );

      // Upload files
      for (final att in _pendingAttachments) {
        await _submissionService.uploadAttachment(
          submissionId: submission.id,
          fileName: att.name,
          fileBytes: att.bytes,
          mimeType: att.mimeType,
          fileSize: att.size,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission uploaded!'),
            backgroundColor: AppConstants.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Work')),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Submit Your Work',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Attach files from your device and/or provide a web link (Google Drive, GitHub, etc.)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Attachments ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('ATTACHMENTS'),
                      TextButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('Upload File'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_pendingAttachments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppConstants.surface,
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(
                            color: AppConstants.cardBorder,
                            style: BorderStyle.solid),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 32, color: AppConstants.textSecondary),
                          SizedBox(height: 8),
                          Text(
                            'No files attached',
                            style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_pendingAttachments.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final att = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AttachmentTile(
                          name: att.name,
                          size: att.size,
                          mimeType: att.mimeType,
                          onDelete: () => setState(
                              () => _pendingAttachments.removeAt(idx)),
                        ),
                      );
                    })),

                  const SizedBox(height: 32),

                  // ── URL ──
                  _SectionLabel('SUBMISSION URL (OPTIONAL)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: AppConstants.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.upload, size: 20),
                      label: const Text('Turn In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppConstants.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String name;
  final int? size;
  final String? mimeType;
  final VoidCallback? onDelete;

  const _AttachmentTile({
    required this.name,
    this.size,
    this.mimeType,
    this.onDelete,
  });

  String get _sizeLabel {
    if (size == null) return '';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get _icon {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType!.startsWith('image/')) return Icons.image_outlined;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mimeType!.contains('word')) return Icons.article_outlined;
    if (mimeType!.contains('spreadsheet') || mimeType!.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (mimeType!.contains('presentation') ||
        mimeType!.contains('powerpoint')) {
      return Icons.slideshow_outlined;
    }
    if (mimeType == 'application/zip') return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 22, color: AppConstants.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_sizeLabel.isNotEmpty)
                  Text(
                    _sizeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close,
                  size: 18, color: AppConstants.error),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class _PendingAttachment {
  final String name;
  final Uint8List bytes;
  final String? mimeType;
  final int? size;

  _PendingAttachment({
    required this.name,
    required this.bytes,
    this.mimeType,
    this.size,
  });
}
