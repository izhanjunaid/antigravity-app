import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/models/submission_model.dart';
import 'package:ibex_app/core/services/assignment_service.dart';
import 'package:ibex_app/core/services/submission_service.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/comment_section_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _assignmentService = AssignmentService();
  final _submissionService = SubmissionService();

  AssignmentModel? _assignment;
  SubmissionModel? _mySubmission;
  List<SubmissionModel> _allSubmissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthGate>();
      _assignment = await _assignmentService.getById(widget.assignmentId);

      if (auth.currentUser?.isStudent == true) {
        _mySubmission = await _submissionService.getMySubmission(
          widget.assignmentId,
        );
      } else {
        _allSubmissions = await _submissionService.getAssignmentSubmissions(
          widget.assignmentId,
        );
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGate>();
    final isStudent = auth.currentUser?.isStudent == true;

    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading assignment...'),
      );
    }

    if (_assignment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Assignment not found',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _assignment!.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Meta row
            Row(
              children: [
                _MetaChip(
                  icon: Icons.calendar_today,
                  label: _assignment!.dueDate != null
                      ? 'Due: ${Helpers.formatDate(_assignment!.dueDate!)}'
                      : 'No due date',
                ),
                const SizedBox(width: 8),
                if (_assignment!.isOverdue)
                  const _StatusBadge(
                    label: 'OVERDUE',
                    color: AppConstants.error,
                  )
                else if (_assignment!.isDueToday)
                  const _StatusBadge(
                    label: 'DUE TODAY',
                    color: AppConstants.warningOrange,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            if (_assignment!.description != null) ...[
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.cardBorder),
                ),
                child: Text(
                  _assignment!.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Points and Topic
            if (_assignment!.points != null || _assignment!.topic != null) ...[
              Row(
                children: [
                  if (_assignment!.points != null)
                    _MetaChip(
                      icon: Icons.grade,
                      label: '${_assignment!.points} pts',
                    ),
                  if (_assignment!.points != null && _assignment!.topic != null)
                    const SizedBox(width: 12),
                  if (_assignment!.topic != null)
                    _MetaChip(
                      icon: Icons.label_outline,
                      label: _assignment!.topic!,
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Attachments
            if (_assignment!.attachments.isNotEmpty) ...[
              const Text(
                'ATTACHMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ..._assignment!.attachments.map((att) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.tryParse(att.fileUrl);
                        if (uri != null) {
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppConstants.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppConstants.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                size: 22, color: AppConstants.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    att.fileName,
                                    style: const TextStyle(
                                      fontSize: 13,
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
                                        fontSize: 11,
                                        color: AppConstants.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new,
                                size: 16, color: AppConstants.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // Student: Submission section
            if (isStudent) ...[
              const Text(
                'MY SUBMISSION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (_mySubmission == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardRadius,
                    ),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.upload_file,
                        size: 40,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No submission yet',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.go(
                          '/submissions/create/${widget.assignmentId}',
                        ),
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('Submit Work'),
                      ),
                    ],
                  ),
                )
              else
                _SubmissionInfoCard(submission: _mySubmission!),
            ],

            // Teacher: Submissions list
            if (!isStudent) ...[
              Text(
                'SUBMISSIONS (${_allSubmissions.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (_allSubmissions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No submissions yet',
                      style: TextStyle(color: AppConstants.textSecondary),
                    ),
                  ),
                )
              else
                ..._allSubmissions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SubmissionInfoCard(
                      submission: s,
                      showName: true,
                      onGrade: () => context.go('/submissions/grade/${s.id}'),
                    ),
                  ),
                ),
            ],
            
            // Classwork Comments Section
            const SizedBox(height: 24),
            const Text(
              'CLASS COMMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            CommentSectionWidget(
              classId: _assignment!.classId,
              classworkId: _assignment!.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppConstants.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SubmissionInfoCard extends StatelessWidget {
  final SubmissionModel submission;
  final bool showName;
  final VoidCallback? onGrade;

  const _SubmissionInfoCard({
    required this.submission,
    this.showName = false,
    this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                submission.studentName ?? 'Student',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppConstants.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Submitted ${Helpers.timeAgo(submission.submittedAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          if (submission.isGraded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grade, size: 16, color: AppConstants.primary),
                const SizedBox(width: 6),
                Text(
                  'Grade: ${submission.grade}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primary,
                  ),
                ),
              ],
            ),
          ],
          if (submission.feedback != null) ...[
            const SizedBox(height: 8),
            Text(
              'Feedback: ${submission.feedback}',
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
          if (submission.submissionUrl != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(submission.submissionUrl!);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: AppConstants.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      submission.submissionUrl!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (submission.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'ATTACHED FILES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: 
                FontWeight.w700,
                color: AppConstants.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            ...submission.attachments.map((att) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 16, color: AppConstants.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: AppConstants.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.download,
                              size: 14, color: AppConstants.textSecondary),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
          if (onGrade != null && !submission.isGraded) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onGrade,
                child: const Text('Grade Submission'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
