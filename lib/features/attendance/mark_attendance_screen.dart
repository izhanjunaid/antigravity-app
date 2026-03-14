import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/enrollment_model.dart';
import 'package:ibex_app/core/services/enrollment_service.dart';
import 'package:ibex_app/core/services/attendance_service.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String classId;

  const MarkAttendanceScreen({super.key, required this.classId});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _enrollmentService = EnrollmentService();
  final _attendanceService = AttendanceService();

  List<EnrollmentModel> _students = [];
  final Map<String, String> _statusMap =
      {}; // userId → 'present'|'absent'|'late'
  bool _isLoading = true;
  bool _isSubmitting = false;
  final DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      _students = await _enrollmentService.getClassEnrollments(widget.classId);
      // Default all to present
      for (final s in _students) {
        _statusMap[s.userId] = 'present';
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    try {
      await _attendanceService.markBulkAttendance(
        classId: widget.classId,
        date: _date,
        studentStatuses: _statusMap,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance submitted!'),
            backgroundColor: AppConstants.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  int get _presentCount =>
      _statusMap.values.where((s) => s == 'present').length;
  int get _lateCount => _statusMap.values.where((s) => s == 'late').length;
  int get _absentCount => _statusMap.values.where((s) => s == 'absent').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                Helpers.formatDate(_date),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding,
                    vertical: 12,
                  ),
                  color: AppConstants.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryChip(
                        label: 'Present',
                        count: _presentCount,
                        color: AppConstants.primary,
                      ),
                      _SummaryChip(
                        label: 'Late',
                        count: _lateCount,
                        color: AppConstants.warningOrange,
                      ),
                      _SummaryChip(
                        label: 'Absent',
                        count: _absentCount,
                        color: AppConstants.error,
                      ),
                      Text(
                        '${_students.length} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Student list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    itemCount: _students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final status = _statusMap[student.userId] ?? 'present';

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
                              radius: 20,
                              backgroundColor: AppConstants.primary.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                Helpers.getInitials(student.userName),
                                style: const TextStyle(
                                  color: AppConstants.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                student.userName ?? 'Student',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            ),
                            // P / L / A toggle
                            _AttendanceToggle(
                              status: status,
                              onChanged: (s) {
                                setState(() {
                                  _statusMap[student.userId] = s;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Submit button
                Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: _isSubmitting
                      ? const LoadingWidget()
                      : ElevatedButton.icon(
                          onPressed: _submitAttendance,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Submit Final Attendance'),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─── P / L / A Toggle Buttons ────────────────────────────────────────
class _AttendanceToggle extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;

  const _AttendanceToggle({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleButton(
          label: 'P',
          isSelected: status == 'present',
          selectedColor: AppConstants.primary,
          onTap: () => onChanged('present'),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          label: 'L',
          isSelected: status == 'late',
          selectedColor: AppConstants.warningOrange,
          onTap: () => onChanged('late'),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          label: 'A',
          isSelected: status == 'absent',
          selectedColor: AppConstants.error,
          onTap: () => onChanged('absent'),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : selectedColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : selectedColor.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : selectedColor,
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
