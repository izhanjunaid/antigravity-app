import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final _classService = ClassService();
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthGate>();
      if (auth.currentUser?.isTeacher == true) {
        _classes = await _classService.getTeacherClasses();
      } else {
        _classes = await _classService.getMyClasses();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          if (isStudent)
            IconButton(
              onPressed: () => context.go('/join-class'),
              icon: const Icon(Icons.add),
              tooltip: 'Join Class',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading classes...')
          : _classes.isEmpty
          ? EmptyStateWidget(
              icon: Icons.class_,
              title: 'No classes yet',
              subtitle: isStudent
                  ? 'Join a class using a class code'
                  : 'No classes assigned to you',
              actionLabel: isStudent ? 'Join Class' : null,
              onAction: isStudent ? () => context.go('/join-class') : null,
            )
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                itemCount: _classes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cls = _classes[index];
                  return _ClassListTile(
                    classModel: cls,
                    onTap: () => context.go('/classes/${cls.id}'),
                  );
                },
              ),
            ),
    );
  }
}

class _ClassListTile extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback? onTap;

  const _ClassListTile({required this.classModel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppConstants.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _subjectColor(
                      classModel.subjectName,
                    ).withValues(alpha: 0.7),
                    _subjectColor(
                      classModel.subjectName,
                    ).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _subjectIcon(classModel.subjectName),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.displayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    classModel.teacherName ?? classModel.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        classModel.classCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppConstants.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('math')) return Colors.blue;
    if (l.contains('eng')) return Colors.purple;
    if (l.contains('sci') || l.contains('phys') || l.contains('chem'))
      return Colors.teal;
    if (l.contains('comp')) return Colors.indigo;
    return Colors.blueGrey;
  }

  IconData _subjectIcon(String s) {
    final l = s.toLowerCase();
    if (l.contains('math')) return Icons.calculate;
    if (l.contains('eng')) return Icons.auto_stories;
    if (l.contains('sci') || l.contains('phys') || l.contains('chem'))
      return Icons.science;
    if (l.contains('comp')) return Icons.computer;
    return Icons.school;
  }
}
