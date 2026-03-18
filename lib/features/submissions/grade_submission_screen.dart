import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/submission_model.dart';
import 'package:ibex_app/core/services/submission_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final String submissionId;

  const GradeSubmissionScreen({super.key, required this.submissionId});

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _submissionService = SubmissionService();
  SubmissionModel? _submission;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    try {
      _submission = await _submissionService.getById(widget.submissionId);
      if (_submission?.grade != null) {
        _gradeController.text = _submission!.grade!;
      }
      if (_submission?.feedback != null) {
        _feedbackController.text = _submission!.feedback!;
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGrade() async {
    if (_gradeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a grade')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _submissionService.gradeSubmission(
        submissionId: widget.submissionId,
        grade: _gradeController.text.trim(),
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade saved!'),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Grade Submission')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            if (_submission != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _submission!.studentName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (_submission!.submissionUrl != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 16,
                            color: AppConstants.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _submission!.submissionUrl!,
                              style: const TextStyle(
                                color: AppConstants.primary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_submission!.attachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'ATTACHED FILES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._submission!.attachments.map((att) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () async {
                                final uri = Uri.tryParse(att.fileUrl);
                                if (uri != null) {
                                  try {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } catch (_) {}
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file_outlined,
                                        size: 18, color: AppConstants.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            att.fileName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppConstants.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (att.sizeLabel.isNotEmpty)
                                            Text(
                                              att.sizeLabel,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppConstants.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.open_in_new,
                                        size: 14,
                                        color: AppConstants.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Grade field
            const Text(
              'GRADE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gradeController,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(hintText: 'A+, 95, etc.'),
            ),
            const SizedBox(height: 20),

            // Feedback
            const Text(
              'FEEDBACK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              style: const TextStyle(color: AppConstants.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Optional feedback for the student...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            _isSaving
                ? const LoadingWidget()
                : ElevatedButton(
                    onPressed: _saveGrade,
                    child: const Text('Save Grade'),
                  ),
          ],
        ),
      ),
    );
  }
}
