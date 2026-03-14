import 'package:flutter/material.dart';
import 'package:ibex_app/core/constants/app_constants.dart';
import 'package:ibex_app/core/models/announcement_model.dart';
import 'package:ibex_app/core/services/announcement_service.dart';
import 'package:ibex_app/shared/widgets/announcement_card.dart';
import 'package:ibex_app/shared/widgets/empty_state_widget.dart';
import 'package:ibex_app/shared/widgets/loading_widget.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final _service = AnnouncementService();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _announcements = await _service.getGlobalAnnouncements();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: _isLoading
          ? const LoadingWidget()
          : _announcements.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No announcements',
              subtitle: 'Check back later for updates',
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                itemCount: _announcements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return AnnouncementCard(announcement: _announcements[index]);
                },
              ),
            ),
    );
  }
}
