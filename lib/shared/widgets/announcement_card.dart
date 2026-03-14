import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/announcement_model.dart';
import 'package:ibex_app/core/utils/helpers.dart';
import 'package:ibex_app/shared/widgets/comment_section_widget.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppConstants.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppConstants.primary.withValues(alpha: 0.2),
                  child: Text(
                    Helpers.getInitials(announcement.posterName),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            announcement.posterName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          if (announcement.posterRole != null) ...[
                            const SizedBox(width: 8),
                            _RoleBadge(role: announcement.posterRole!),
                          ],
                        ],
                      ),
                      Text(
                        Helpers.timeAgo(announcement.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              announcement.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textPrimary,
                height: 1.5,
              ),
            ),
            // Attachment
            if (announcement.attachmentUrl != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppConstants.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Attachment',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Comment section
            if (announcement.classId != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppConstants.cardBorder),
              ),
              CommentSectionWidget(
                classId: announcement.classId!,
                postId: announcement.id,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'teacher' => AppConstants.success,
      'principal' => AppConstants.warningOrange,
      'section_head' => AppConstants.primary,
      _ => AppConstants.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
