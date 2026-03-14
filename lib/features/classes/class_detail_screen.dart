import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/models/announcement_model.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/models/enrollment_model.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/announcement_service.dart';
import 'package:ibex_app/core/services/assignment_service.dart';
import 'package:ibex_app/core/services/enrollment_service.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/announcement_card.dart';
import 'package:ibex_app/shared/widgets/assignment_card.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  final _classService = ClassService();
  final _announcementService = AnnouncementService();
  final _assignmentService = AssignmentService();
  final _enrollmentService = EnrollmentService();

  late TabController _tabController;
  ClassModel? _classModel;
  List<AnnouncementModel> _announcements = [];
  List<AssignmentModel> _assignments = [];
  List<EnrollmentModel> _enrollments = [];
  bool _isLoading = true;

  // Post composer
  final _postController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _classService.getClassById(widget.classId),
        _announcementService.getClassAnnouncements(widget.classId),
        _assignmentService.getClassAssignments(widget.classId),
        _enrollmentService.getClassEnrollments(widget.classId),
      ]);
      if (mounted) {
        setState(() {
          _classModel = results[0] as ClassModel?;
          _announcements = results[1] as List<AnnouncementModel>;
          _assignments = results[2] as List<AssignmentModel>;
          _enrollments = results[3] as List<EnrollmentModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postAnnouncement() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await _announcementService.createAnnouncement(
        classId: widget.classId,
        content: content,
      );
      _postController.clear();
      // Reload announcements
      final announcements = await _announcementService.getClassAnnouncements(
        widget.classId,
      );
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isPosting = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGate>();
    final isTeacher = auth.currentUser?.isTeacher == true;

    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading class...'));
    }

    if (_classModel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Class not found',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _classModel!.displayTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_classModel!.subtitle} • ${_enrollments.length} Students',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (isTeacher)
            IconButton(
              onPressed: () => context.go('/attendance/${widget.classId}'),
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Mark Attendance',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primary,
          labelColor: AppConstants.primary,
          unselectedLabelColor: AppConstants.textSecondary,
          tabs: const [
            Tab(text: 'Stream'),
            Tab(text: 'Classwork'),
            Tab(text: 'People'),
          ],
        ),
      ),
      floatingActionButton: isTeacher
          ? AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final onClasswork = _tabController.index == 1;
                if (!onClasswork) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () async {
                    await context.push('/assignments/create/${widget.classId}');
                    _loadData();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                  backgroundColor: AppConstants.primary,
                  foregroundColor: Colors.white,
                );
              },
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _StreamTab(
            announcements: _announcements,
            postController: _postController,
            isPosting: _isPosting,
            onPost: _postAnnouncement,
            isTeacher: isTeacher,
          ),
          _ClassworkTab(
            assignments: _assignments,
            isTeacher: isTeacher,
            classId: widget.classId,
          ),
          _PeopleTab(classModel: _classModel!, enrollments: _enrollments),
        ],
      ),
    );
  }
}

// ─── Stream Tab ──────────────────────────────────────────────────────
class _StreamTab extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final TextEditingController postController;
  final bool isPosting;
  final VoidCallback onPost;
  final bool isTeacher;

  const _StreamTab({
    required this.announcements,
    required this.postController,
    required this.isPosting,
    required this.onPost,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      children: [
        // Post composer (teachers only)
        if (isTeacher)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppConstants.cardBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppConstants.primary,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: postController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Post an announcement to your class...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: onPost,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppConstants.primary,
                        ),
                      ),
              ],
            ),
          ),
        if (isTeacher) const SizedBox(height: 16),

        // Announcements
        if (announcements.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No announcements yet',
              subtitle: 'Be the first to post something!',
            ),
          )
        else
          ...announcements.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnnouncementCard(announcement: a),
            ),
          ),
      ],
    );
  }
}

// ─── Classwork Tab ───────────────────────────────────────────────────
class _ClassworkTab extends StatelessWidget {
  final List<AssignmentModel> assignments;
  final bool isTeacher;
  final String classId;

  const _ClassworkTab({
    required this.assignments,
    required this.isTeacher,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return assignments.isEmpty
        ? EmptyStateWidget(
            icon: Icons.assignment_outlined,
            title: 'No assignments yet',
            subtitle: isTeacher
                ? 'Create your first assignment'
                : 'Nothing due yet',
            actionLabel: isTeacher ? 'Create Assignment' : null,
            onAction: isTeacher
                ? () => context.push('/assignments/create/$classId')
                : null,
          )
        : ListView.separated(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            itemCount: assignments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return AssignmentCard(
                assignment: assignment,
                onTap: () => context.go('/assignments/${assignment.id}'),
              );
            },
          );
  }
}

// ─── People Tab ──────────────────────────────────────────────────────
class _PeopleTab extends StatelessWidget {
  final ClassModel classModel;
  final List<EnrollmentModel> enrollments;

  const _PeopleTab({required this.classModel, required this.enrollments});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      children: [
        // Teacher
        const Text(
          'TEACHER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          tileColor: AppConstants.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            side: const BorderSide(color: AppConstants.cardBorder),
          ),
          leading: CircleAvatar(
            backgroundColor: AppConstants.success.withValues(alpha: 0.2),
            child: Text(
              Helpers.getInitials(classModel.teacherName),
              style: const TextStyle(
                color: AppConstants.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(classModel.teacherName ?? 'Teacher'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppConstants.success),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TEACHER',
              style: TextStyle(
                fontSize: 10,
                color: AppConstants.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Students
        Text(
          'STUDENTS (${enrollments.length})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        if (enrollments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                'No students enrolled yet',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            ),
          )
        else
          ...enrollments.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: AppConstants.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppConstants.cardBorder),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppConstants.primary.withValues(alpha: 0.2),
                  child: Text(
                    Helpers.getInitials(e.userName),
                    style: const TextStyle(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(e.userName ?? 'Student'),
              ),
            ),
          ),
      ],
    );
  }
}
