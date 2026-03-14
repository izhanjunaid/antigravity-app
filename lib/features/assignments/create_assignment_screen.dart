import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/assignment_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;

  const CreateAssignmentScreen({super.key, required this.classId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController(text: '100');
  final _topicController = TextEditingController();
  final _assignmentService = AssignmentService();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isLoading = false;
  bool _noGrade = false;

  // Pending file attachments (not yet uploaded, staged locally)
  final List<_PendingAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primary,
            onPrimary: Colors.white,
            surface: AppConstants.surface,
            onSurface: AppConstants.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() => _dueDate = date);
      // Also pick time
      await _pickTime();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primary,
            onPrimary: Colors.white,
            surface: AppConstants.surface,
            onSurface: AppConstants.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() => _dueTime = time);
    }
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

  DateTime? _combinedDueDateTime() {
    if (_dueDate == null) return null;
    final date = _dueDate!;
    if (_dueTime != null) {
      return DateTime(
          date.year, date.month, date.day, _dueTime!.hour, _dueTime!.minute);
    }
    return DateTime(date.year, date.month, date.day, 23, 59);
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final points = _noGrade
          ? null
          : int.tryParse(_pointsController.text.trim()) ?? 100;
      final topic = _topicController.text.trim().isEmpty
          ? null
          : _topicController.text.trim();
      final desc = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();

      final assignment = await _assignmentService.createAssignment(
        classId: widget.classId,
        title: title,
        description: desc,
        dueDate: _combinedDueDateTime(),
        points: points,
        topic: topic,
      );

      // Upload all pending attachments
      for (final att in _pendingAttachments) {
        await _assignmentService.uploadAttachment(
          assignmentId: assignment.id,
          fileName: att.name,
          fileBytes: att.bytes,
          mimeType: att.mimeType,
          fileSize: att.size,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _isLoading ? null : _create,
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Assign'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          children: [
            // ── Title ──
            _SectionLabel('TITLE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Assignment title',
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Title is required' : null,
            ),
            const SizedBox(height: 24),

            // ── Instructions ──
            _SectionLabel('INSTRUCTIONS'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Instructions for students...',
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Points and Topic row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('POINTS'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pointsController,
                              enabled: !_noGrade,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: _noGrade
                                    ? AppConstants.textSecondary
                                    : AppConstants.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '100',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              const Text(
                                'No grade',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              Switch(
                                value: _noGrade,
                                onChanged: (v) => setState(() => _noGrade = v),
                                activeColor: AppConstants.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Topic
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('TOPIC'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _topicController,
                        style: const TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Chapter 4',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Due Date ──
            _SectionLabel('DUE DATE & TIME'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueDate != null
                            ? '${DateFormat('EEE, MMM d, yyyy').format(_dueDate!)}${_dueTime != null ? ' at ${_dueTime!.format(context)}' : ''}'
                            : 'Select due date & time (optional)',
                        style: TextStyle(
                          color: _dueDate != null
                              ? AppConstants.textPrimary
                              : AppConstants.textSecondary,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _dueDate = null;
                          _dueTime = null;
                        }),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Attachments ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('ATTACHMENTS'),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text('Add File'),
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
            if (_pendingAttachments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(
                      color: AppConstants.cardBorder,
                      style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 36, color: AppConstants.textSecondary),
                    SizedBox(height: 8),
                    Text(
                      'No attachments yet',
                      style: TextStyle(
                          color: AppConstants.textSecondary, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Add File" to attach documents, images, or other files',
                      style: TextStyle(
                          color: AppConstants.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
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
                    onDelete: () =>
                        setState(() => _pendingAttachments.removeAt(idx)),
                  ),
                );
              })),

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
        fontSize: 11,
        fontWeight: FontWeight.w700,
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
    if (mimeType!.contains('spreadsheet') || mimeType!.contains('excel'))
      return Icons.table_chart_outlined;
    if (mimeType!.contains('presentation') || mimeType!.contains('powerpoint'))
      return Icons.slideshow_outlined;
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
                  size: 18, color: AppConstants.textSecondary),
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
