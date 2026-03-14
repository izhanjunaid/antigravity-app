import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/services/announcement_service.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String? classId;
  final String? sectionId;

  const CreateAnnouncementScreen({super.key, this.classId, this.sectionId});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _contentController = TextEditingController();
  final _service = AnnouncementService();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write something')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.createAnnouncement(
        content: content,
        classId: widget.classId,
        sectionId: widget.sectionId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted!'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Announcement')),
      body: _isLoading
          ? const LoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'ANNOUNCEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    style: const TextStyle(color: AppConstants.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Write your announcement...',
                    ),
                    maxLines: 8,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _post,
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('Post Announcement'),
                  ),
                ],
              ),
            ),
    );
  }
}
