import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/notification_service.dart';
import 'package:ibex_app/shared/themes/app_theme.dart';
import 'package:ibex_app/features/auth/auth_gate.dart';
import 'package:ibex_app/features/auth/login_screen.dart';
import 'package:ibex_app/features/dashboard/student_dashboard.dart';
import 'package:ibex_app/features/dashboard/teacher_dashboard.dart';
import 'package:ibex_app/features/dashboard/principal_dashboard.dart';
import 'package:ibex_app/features/dashboard/section_head_dashboard.dart';
import 'package:ibex_app/features/profile/profile_screen.dart';
import 'package:ibex_app/features/classes/class_list_screen.dart';
import 'package:ibex_app/features/classes/class_detail_screen.dart';
import 'package:ibex_app/features/classes/join_class_screen.dart';
import 'package:ibex_app/features/assignments/assignment_list_screen.dart';
import 'package:ibex_app/features/assignments/assignment_detail_screen.dart';
import 'package:ibex_app/features/assignments/create_assignment_screen.dart';
import 'package:ibex_app/features/submissions/submission_screen.dart';
import 'package:ibex_app/features/submissions/grade_submission_screen.dart';
import 'package:ibex_app/features/announcements/announcement_list_screen.dart';
import 'package:ibex_app/features/announcements/create_announcement_screen.dart';
import 'package:ibex_app/features/attendance/mark_attendance_screen.dart';
import 'package:ibex_app/features/attendance/view_attendance_screen.dart';
import 'package:ibex_app/features/grades/grade_management_screen.dart';
import 'package:ibex_app/features/sections/section_management_screen.dart';
import 'package:ibex_app/features/admin_classes/admin_class_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  runApp(const IbexApp());
}

class IbexApp extends StatefulWidget {
  const IbexApp({super.key});

  @override
  State<IbexApp> createState() => _IbexAppState();
}

class _IbexAppState extends State<IbexApp> {
  late final AuthGate _authGate;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authGate = AuthGate();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      refreshListenable: _authGate,
      initialLocation: '/',
      redirect: (context, state) {
        final isLoading = _authGate.isLoading;
        if (isLoading) return null;

        final isLoggedIn = _authGate.isAuthenticated;
        final isOnLogin = state.matchedLocation == '/login';

        if (!isLoggedIn && !isOnLogin) return '/login';
        if (isLoggedIn && isOnLogin) return '/';

        return null;
      },
      routes: [
        // ── Root redirect by role ──
        GoRoute(
          path: '/',
          redirect: (context, state) {
            final role = _authGate.userRole;
            return switch (role) {
              AppConstants.roleStudent => '/student-dashboard',
              AppConstants.roleTeacher => '/teacher-dashboard',
              AppConstants.roleSectionHead => '/section-head-dashboard',
              AppConstants.rolePrincipal => '/principal-dashboard',
              _ => '/login',
            };
          },
        ),

        // ── Auth ──
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        // ── Dashboards ──
        GoRoute(
          path: '/student-dashboard',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/teacher-dashboard',
          builder: (context, state) => const TeacherDashboard(),
        ),
        GoRoute(
          path: '/principal-dashboard',
          builder: (context, state) => const PrincipalDashboard(),
        ),
        GoRoute(
          path: '/section-head-dashboard',
          builder: (context, state) => const SectionHeadDashboard(),
        ),

        // ── Profile ──
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // ── Classes ──
        GoRoute(
          path: '/classes',
          builder: (context, state) => const ClassListScreen(),
        ),
        GoRoute(
          path: '/classes/:id',
          builder: (context, state) =>
              ClassDetailScreen(classId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/join-class',
          builder: (context, state) => const JoinClassScreen(),
        ),

        // ── Assignments ──
        GoRoute(
          path: '/assignments',
          builder: (context, state) => const AssignmentListScreen(),
        ),
        GoRoute(
          path: '/assignments/:id',
          builder: (context, state) =>
              AssignmentDetailScreen(assignmentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/assignments/create/:classId',
          builder: (context, state) =>
              CreateAssignmentScreen(classId: state.pathParameters['classId']!),
        ),

        // ── Submissions ──
        GoRoute(
          path: '/submissions/create/:assignmentId',
          builder: (context, state) => SubmissionScreen(
            assignmentId: state.pathParameters['assignmentId']!,
          ),
        ),
        GoRoute(
          path: '/submissions/grade/:submissionId',
          builder: (context, state) => GradeSubmissionScreen(
            submissionId: state.pathParameters['submissionId']!,
          ),
        ),

        // ── Announcements ──
        GoRoute(
          path: '/announcements',
          builder: (context, state) => const AnnouncementListScreen(),
        ),
        GoRoute(
          path: '/announcements/create',
          builder: (context, state) => const CreateAnnouncementScreen(),
        ),

        // ── Attendance ──
        GoRoute(
          path: '/attendance/:classId',
          builder: (context, state) =>
              MarkAttendanceScreen(classId: state.pathParameters['classId']!),
        ),
        GoRoute(
          path: '/attendance/view/:classId',
          builder: (context, state) =>
              ViewAttendanceScreen(classId: state.pathParameters['classId']!),
        ),

        // ── Admin (placeholders) ──
        GoRoute(
          path: '/grades',
          builder: (context, state) => const GradeManagementScreen(),
        ),
        GoRoute(
          path: '/sections',
          builder: (context, state) => const SectionManagementScreen(),
        ),
        GoRoute(
          path: '/admin-classes',
          builder: (context, state) => const AdminClassManagementScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authGate.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authGate,
      child: MaterialApp.router(
        title: 'Ibex Classroom',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: NotificationService.messengerKey,
        routerConfig: _router,
      ),
    );
  }
}
