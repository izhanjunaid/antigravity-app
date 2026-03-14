import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/attendance_model.dart';
import 'package:ibex_app/core/services/attendance_service.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';

class ViewAttendanceScreen extends StatefulWidget {
  final String classId;

  const ViewAttendanceScreen({super.key, required this.classId});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  final _service = AttendanceService();
  List<AttendanceModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _records = await _service.getClassAttendance(
        classId: widget.classId,
        date: DateTime.now(),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: _isLoading
          ? const LoadingWidget()
          : _records.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.fact_check_outlined,
              title: 'No records',
              subtitle: 'Attendance not marked for today',
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                itemCount: _records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final r = _records[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppConstants.primary.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            Helpers.getInitials(r.studentName),
                            style: const TextStyle(
                              color: AppConstants.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.studentName ?? 'Student',
                            style: const TextStyle(
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ),
                        _StatusBadge(status: r.status),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'present' => (AppConstants.primary, 'PRESENT'),
      'late' => (AppConstants.warningOrange, 'LATE'),
      'absent' => (AppConstants.error, 'ABSENT'),
      _ => (AppConstants.textSecondary, status.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
