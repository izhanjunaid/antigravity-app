import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/user_service.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/stat_card.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final _userService = UserService();
  final _classService = ClassService();

  int _studentCount = 0;
  int _teacherCount = 0;
  int _classCount = 0;
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
        _userService.countByRole('student'),
        _userService.countByRole('teacher'),
        _classService.getClassCount(),
      ]);
      if (mounted) {
        setState(() {
          _studentCount = results[0];
          _teacherCount = results[1];
          _classCount = results[2];
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
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppConstants.primary,
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    user?.name ?? 'Principal Admin',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.search),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Overview label
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            StatCard(
                              icon: Icons.groups,
                              label: 'Students',
                              value: '$_studentCount',
                              iconColor: AppConstants.primary,
                            ),
                            StatCard(
                              icon: Icons.school,
                              label: 'Teachers',
                              value: '$_teacherCount',
                              iconColor: AppConstants.success,
                            ),
                            StatCard(
                              icon: Icons.class_,
                              label: 'Classes',
                              value: '$_classCount',
                              iconColor: AppConstants.warningOrange,
                            ),
                            const StatCard(
                              icon: Icons.check_circle_outline,
                              label: 'Attendance',
                              value: '--',
                              iconColor: AppConstants.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QuickActionButton(
                              icon: Icons.grade,
                              label: 'Grades',
                              onTap: () => context.go('/grades'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionButton(
                              icon: Icons.view_list,
                              label: 'Sections',
                              onTap: () => context.go('/sections'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionButton(
                              icon: Icons.class_,
                              label: 'Classes',
                              onTap: () => context.go('/admin-classes'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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
              context.go('/grades');
              break;
            case 2:
              context.go('/sections');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade_outlined),
            label: 'Grades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_outlined),
            label: 'Sections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'More',
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppConstants.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppConstants.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
