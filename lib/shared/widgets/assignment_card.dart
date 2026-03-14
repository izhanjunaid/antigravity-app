import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:ibex_app/core/utils/helpers.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback? onTap;

  const AssignmentCard({super.key, required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dueLabel = Helpers.daysUntilDue(assignment.dueDate);
    final isOverdue = assignment.isOverdue;
    final isDueToday = assignment.isDueToday;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: isOverdue
                ? AppConstants.error.withValues(alpha: 0.4)
                : AppConstants.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Due badge
            if (dueLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBadgeColor(
                    isOverdue,
                    isDueToday,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getBadgeColor(isOverdue, isDueToday),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Title
            Text(
              assignment.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Date row
            if (assignment.dueDate != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.formatDateTime(assignment.dueDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            // Class name
            if (assignment.className != null) ...[
              const SizedBox(height: 4),
              Text(
                assignment.className!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(bool isOverdue, bool isDueToday) {
    if (isOverdue) return AppConstants.error;
    if (isDueToday) return AppConstants.warningOrange;
    return AppConstants.primary;
  }
}
