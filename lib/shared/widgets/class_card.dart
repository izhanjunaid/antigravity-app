import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/class_model.dart';

class ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback? onTap;
  final String? statusLabel;
  final Color? statusColor;

  const ClassCard({
    super.key,
    required this.classModel,
    this.onTap,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppConstants.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.cardRadius),
                ),
                gradient: LinearGradient(
                  colors: [
                    _getSubjectColor(
                      classModel.subjectName,
                    ).withValues(alpha: 0.8),
                    _getSubjectColor(
                      classModel.subjectName,
                    ).withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getSubjectIcon(classModel.subjectName),
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (statusLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor ?? AppConstants.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          classModel.teacherName ?? classModel.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('calculus')) return Colors.blue;
    if (s.contains('english') || s.contains('literature')) return Colors.purple;
    if (s.contains('science') ||
        s.contains('physics') ||
        s.contains('chemistry')) {
      return Colors.teal;
    }
    if (s.contains('computer') || s.contains('digital')) return Colors.indigo;
    if (s.contains('urdu') || s.contains('islamiyat')) return Colors.green;
    if (s.contains('history') || s.contains('social')) return Colors.orange;
    return Colors.blueGrey;
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('calculus')) return Icons.calculate;
    if (s.contains('english') || s.contains('literature')) {
      return Icons.auto_stories;
    }
    if (s.contains('science') ||
        s.contains('physics') ||
        s.contains('chemistry')) {
      return Icons.science;
    }
    if (s.contains('computer') || s.contains('digital')) return Icons.computer;
    if (s.contains('urdu') || s.contains('islamiyat')) return Icons.menu_book;
    if (s.contains('history') || s.contains('social')) return Icons.public;
    return Icons.school;
  }
}
