import 'package:flutter/material.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/models/class_model.dart';
import 'package:ibex_app/core/services/assignment_service.dart';
import 'package:ibex_app/core/services/class_service.dart';
import 'package:ibex_app/core/services/attendance_service.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/shared/widgets/modern_class_card.dart';
import 'package:ibex_app/shared/widgets/modern_assignment_card.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Modern Design Colors matching HTML
const _bgDark = Color(0xFF101622);
const _surfaceDark = Color(0xFF192233);
const _borderDark = Color(0xFF232F48);
const _primary = Color(0xFF135BEC);
const _textSlate100 = Color(0xFFF1F5F9);
const _textSlate400 = Color(0xFF94A3B8);

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _classService = ClassService();
  final _assignmentService = AssignmentService();
  final _attendanceService = AttendanceService();

  List<ClassModel> _classes = [];
  List<AssignmentModel> _upcomingAssignments = [];
  double _attendancePercent = 100;
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
      final results = await Future.wait([
        _classService.getMyClasses(),
        _assignmentService.getUpcomingAssignments(),
        _attendanceService.getAttendancePercentage(auth.currentUser!.id),
      ]);
      if (mounted) {
        setState(() {
          _classes = results[0] as List<ClassModel>;
          _upcomingAssignments = results[1] as List<AssignmentModel>;
          _attendancePercent = results[2] as double;
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

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgDark,
        body: LoadingWidget(message: 'Loading dashboard...'),
      );
    }

    return Scaffold(
      backgroundColor: _bgDark,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _primary,
        backgroundColor: _surfaceDark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom Header
            SliverAppBar(
              backgroundColor: _bgDark,
              pinned: true,
              elevation: 0,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary.withValues(alpha: 0.4), width: 2),
                            color: _primary.withValues(alpha: 0.2),
                          ),
                          child: ClipOval(
                            child: user?.profilePic != null
                                ? Image.network(user!.profilePic!, fit: BoxFit.cover)
                                : Icon(Icons.person, color: _primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Greeting
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'WELCOME BACK,',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _textSlate400,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Lexend',
                                ),
                              ),
                              Text(
                                user?.name ?? 'Student',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textSlate100,
                                  fontFamily: 'Lexend',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        Row(
                          children: [
                            _buildHeaderIconButton(Icons.notifications, hasBadge: true, badgeColor: Colors.red),
                            const SizedBox(width: 8),
                            _buildHeaderIconButton(Icons.campaign, hasBadge: true, badgeColor: _primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Stats Box
                    _buildStatsBox(),
                    
                    const SizedBox(height: 24),
                    
                    // Active Classes Header
                    _buildSectionHeader('Active Classes', 'View All', () => context.go('/classes')),
                    
                    const SizedBox(height: 12),
                    
                    // Active Classes List
                    if (_classes.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.class_,
                        title: 'No Active Classes',
                        subtitle: 'Join a class using a code.',
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _classes.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return ModernClassCard(
                              classModel: _classes[index],
                              onTap: () => context.go('/classes/${_classes[index].id}'),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    
                    // Upcoming Assignments Header
                    _buildSectionHeader('Upcoming Assignments', null, null),
                    
                    const SizedBox(height: 12),
                    
                    // Upcoming Assignments List
                    if (_upcomingAssignments.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.assignment_turned_in,
                        title: 'All caught up!',
                        subtitle: 'No upcoming assignments.',
                      )
                    else
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _upcomingAssignments.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return ModernAssignmentCard(
                              assignment: _upcomingAssignments[index],
                              onTap: () => context.go('/assignments/${_upcomingAssignments[index].id}'),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    
                    // Timetable Header
                    _buildSectionHeader("Today's Timetable", null, null),
                    
                    const SizedBox(height: 12),
                    
                    // Timetable List (Mocked to match design as backend has no timetable table)
                    _buildTimetable(),
                    
                    const SizedBox(height: 100), // Padding for bottom nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Modern Floating Bottom Nav
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary,
            border: Border.all(color: _bgDark, width: 4),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              // Action logic
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {bool hasBadge = false, Color? badgeColor}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: _textSlate100, size: 20),
          if (hasBadge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBox() {
    return Container(
      width: double.infinity,
      height: 140, // Fixed height to match design proportions after removing bottom content
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(
            right: -32, // -right-8 in tailwind
            top: -32,   // -top-8 in tailwind
            child: Container(
              width: 128, // size-32 in tailwind
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: -16,   // -right-4 in tailwind
            bottom: -16,  // -bottom-4 in tailwind
            child: Container(
              width: 96,  // size-24 in tailwind
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          // Content overlay
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Today's Attendance",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lexend',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_attendancePercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36, // Slightly larger to match the bold look in the image
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Perfect standing',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textSlate100,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lexend',
            letterSpacing: -0.5,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Lexend',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimetable() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTimetableRow(
            time: '09:00',
            ampm: 'AM',
            subject: 'Mathematics',
            room: 'Lecture • Hall A',
            color: _primary,
            statusIcon: Icons.chevron_right,
            isFirst: true,
          ),
          Divider(color: _borderDark, height: 1),
          Opacity(
            opacity: 0.6, // Passed class
            child: _buildTimetableRow(
              time: '11:30',
              ampm: 'AM',
              subject: 'English Lit',
              room: 'Seminar • Room 202',
              color: const Color(0xFF94A3B8), // slate-400
              statusIcon: Icons.chevron_right,
            ),
          ),
          Divider(color: _borderDark, height: 1),
          Container(
            color: _primary.withValues(alpha: 0.05), // Active class background highlight
            child: _buildTimetableRow(
              time: '02:00',
              ampm: 'PM',
              subject: 'Chemistry Lab',
              room: 'Practical • Lab 03',
              color: _primary,
              statusIcon: Icons.pending,
              isActive: true,
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableRow({
    required String time,
    required String ampm,
    required String subject,
    required String room,
    required Color color,
    required IconData statusIcon,
    bool isActive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isActive ? color : _textSlate100,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                  ),
                ),
                Text(
                  ampm,
                  style: TextStyle(
                    color: isActive ? color : _textSlate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Vertical Line
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    color: isActive ? color : _textSlate100,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                  ),
                ),
                Text(
                  room,
                  style: TextStyle(
                    color: isActive ? color.withValues(alpha: 0.7) : _textSlate400,
                    fontSize: 12,
                    fontFamily: 'Lexend',
                  ),
                ),
              ],
            ),
          ),
          // Trailing Icon
          Icon(
            statusIcon,
            color: isActive ? color : _textSlate400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _surfaceDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: _borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', true, () => {}),
          _buildNavItem(Icons.menu_book, 'Classes', false, () => context.go('/classes')),
          const SizedBox(width: 40), // Space for FAB
          _buildNavItem(Icons.assignment, 'Tasks', false, () => context.go('/assignments')),
          _buildNavItem(Icons.person, 'Profile', false, () => context.go('/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? _primary : _textSlate400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _primary : _textSlate400,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      ),
    );
  }
}
