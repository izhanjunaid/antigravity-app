import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/services/assignment_service.dart';
import 'package:ibex_app/shared/widgets/assignment_card.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen>
    with SingleTickerProviderStateMixin {
  final _assignmentService = AssignmentService();
  late TabController _tabController;
  List<AssignmentModel> _all = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _all = await _assignmentService.getUpcomingAssignments();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _all.where((a) => !a.isOverdue).toList();
    final overdue = _all.where((a) => a.isOverdue).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primary,
          labelColor: AppConstants.primary,
          unselectedLabelColor: AppConstants.textSecondary,
          tabs: [
            Tab(text: 'All (${_all.length})'),
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Overdue (${overdue.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _AssignmentTab(assignments: _all, onRefresh: _loadData),
                _AssignmentTab(assignments: upcoming, onRefresh: _loadData),
                _AssignmentTab(assignments: overdue, onRefresh: _loadData),
              ],
            ),
    );
  }
}

class _AssignmentTab extends StatelessWidget {
  final List<AssignmentModel> assignments;
  final Future<void> Function() onRefresh;

  const _AssignmentTab({required this.assignments, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'No assignments',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        itemCount: assignments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = assignments[index];
          return AssignmentCard(
            assignment: a,
            onTap: () => context.go('/assignments/${a.id}'),
          );
        },
      ),
    );
  }
}
