import 'package:flutter/material.dart';
import 'package:ibex_app/core/models/assignment_model.dart';
import 'package:intl/intl.dart';

class ModernAssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onTap;

  const ModernAssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine styles based on due date proximity (mock logic based on design)
    final now = DateTime.now();
    final difference = assignment.dueDate?.difference(now).inDays ?? 999;
    
    Color bgColor;
    Color borderColor;
    Color badgeColor;
    String badgeText;
    
    if (difference <= 0) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1); // Red 500
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Due Today';
    } else if (difference <= 2) {
      bgColor = const Color(0xFF135BEC).withValues(alpha: 0.1); // Primary
      borderColor = const Color(0xFF135BEC).withValues(alpha: 0.2);
      badgeColor = const Color(0xFF135BEC);
      badgeText = 'In $difference Days';
    } else {
      bgColor = const Color(0xFF192233); // Surface Dark
      borderColor = const Color(0xFF232F48); // Border Dark
      badgeColor = const Color(0xFF64748B); // Slate 500
      badgeText = 'Next Week';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Expanded(
              child: Text(
                assignment.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF8E99A4),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.dueDate != null 
                        ? DateFormat('MMM d, hh:mm a').format(assignment.dueDate!)
                        : 'No Due Date',
                    style: const TextStyle(
                      color: Color(0xFF8E99A4),
                      fontSize: 11,
                      fontFamily: 'Lexend',
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
    );
  }
}
