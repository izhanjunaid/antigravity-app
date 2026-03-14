import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/section_service.dart';
import 'package:ibex_app/core/models/section_model.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SectionHeadDashboard extends StatefulWidget {
  const SectionHeadDashboard({super.key});

  @override
  State<SectionHeadDashboard> createState() => _SectionHeadDashboardState();
}

class _SectionHeadDashboardState extends State<SectionHeadDashboard> {
  final _sectionService = SectionService();
  final _classService = ClassService();

  List<SectionModel> _mySections = [];
  List<ClassModel> _sectionClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _mySections = await _sectionService.getMySections();
      if (_mySections.isNotEmpty) {
        _sectionClasses = await _classService.getClassesBySection(
          _mySections.first.id,
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
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Section Head'),
            Text(
              user?.name ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section info
                      if (_mySections.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF283593)],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mySections.first.displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_sectionClasses.length} Classes',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Classes in section
                      const Text(
                        'Classes in My Section',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._sectionClasses.map(
                        (cls) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: AppConstants.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardRadius,
                              ),
                              side: const BorderSide(
                                color: AppConstants.cardBorder,
                              ),
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.class_,
                                color: AppConstants.primary,
                              ),
                            ),
                            title: Text(cls.subjectName),
                            subtitle: Text(cls.teacherName ?? 'No teacher'),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppConstants.textSecondary,
                            ),
                            onTap: () => context.go('/classes/${cls.id}'),
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
              context.go('/announcements');
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
            icon: Icon(Icons.campaign_outlined),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
