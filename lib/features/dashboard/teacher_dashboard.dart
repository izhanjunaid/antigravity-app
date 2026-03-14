import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/submission_service.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/class_card.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _classService = ClassService();
  final _submissionService = SubmissionService();

  List<ClassModel> _classes = [];
  int _ungradedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _classService.getTeacherClasses(),
        _submissionService.getUngradedCount(),
      ]);
      if (mounted) {
        setState(() {
          _classes = results[0] as List<ClassModel>;
          _ungradedCount = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGate>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        title: Column(
          children: [
            const Text(
              'Teacher Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Welcome back, ${user?.name ?? "Teacher"}',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (_ungradedCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppConstants.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_ungradedCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Classes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Classes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/classes'),
                            child: const Text(
                              'View All',
                              style: TextStyle(color: AppConstants.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_classes.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.class_,
                          title: 'No classes assigned',
                          subtitle: 'Contact the principal to assign classes',
                        )
                      else
                        SizedBox(
                          height: 170,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _classes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ClassCard(
                                classModel: _classes[index],
                                onTap: () => context.go(
                                  '/classes/${_classes[index].id}',
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Pending Submissions
                      if (_ungradedCount > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.surface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                            border: Border.all(color: AppConstants.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppConstants.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: AppConstants.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending Assignments',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$_ungradedCount Submissions need grading',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppConstants.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_ungradedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // My Classes List
                      const Text(
                        'My Classes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._classes.map(
                        (cls) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TeacherClassTile(
                            classModel: cls,
                            onTap: () => context.go('/classes/${cls.id}'),
                            onMarkAttendance: () =>
                                context.go('/attendance/${cls.id}'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/classes');
              break;
            case 2:
              context.go('/assignments');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_outlined),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TeacherClassTile extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAttendance;

  const _TeacherClassTile({
    required this.classModel,
    this.onTap,
    this.onMarkAttendance,
  });

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
                color: AppConstants.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_, color: AppConstants.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.displayTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    classModel.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onMarkAttendance,
              icon: const Icon(Icons.person_add_alt_1, size: 16),
              label: const Text('Attendance', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
