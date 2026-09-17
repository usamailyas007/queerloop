import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../communities/provider/communities_provider.dart';
import '../models/announcement.dart';
import '../provider/announcements_provider.dart';
import '../widgets/announcement_card.dart';
import '../widgets/announcement_compose_card.dart';
import '../widgets/announcements_sent_list.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  AnnouncementAudience _audience = AnnouncementAudience.everyone;
  String? _communityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AnnouncementsProvider>().loadInitial();
      context.read<CommunitiesProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onAudienceChanged(AnnouncementAudience a) {
    setState(() {
      _audience = a;
      if (a != AnnouncementAudience.community) {
        _communityId = null;
      }
    });
  }

  Future<void> _send() async {
    final String title = _titleController.text.trim();
    final String body = _messageController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('Title and message are required.');
      return;
    }
    if (_audience == AnnouncementAudience.community && _communityId == null) {
      _snack('Pick a community for this announcement.');
      return;
    }

    final AnnouncementsProvider provider = context.read<AnnouncementsProvider>();
    final Announcement? created = await provider.createAnnouncement(
      title: title,
      body: body,
      audience: _audience,
      communityId: _communityId,
    );

    if (!mounted) {
      return;
    }
    if (created != null) {
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _audience = AnnouncementAudience.everyone;
        _communityId = null;
      });
      _snack('Announcement published.');
    } else {
      _snack(provider.error ?? 'Could not publish the announcement.');
      provider.clearError();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool sending = context.select<AnnouncementsProvider, bool>(
      (AnnouncementsProvider p) => p.isSending,
    );

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Announcements',
                style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sent as a push notification and pinned in the notifications list',
                style: TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: AnnouncementComposeCard(
                        titleController: _titleController,
                        messageController: _messageController,
                        audience: _audience,
                        onAudienceChanged: _onAudienceChanged,
                        communityId: _communityId,
                        onCommunitySelected: (String id) => setState(() => _communityId = id),
                        sending: sending,
                        onSend: _send,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AnnouncementCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const AnnouncementCardTitle('Sent'),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: Consumer<AnnouncementsProvider>(
                                builder: (_, AnnouncementsProvider provider, _) =>
                                    AnnouncementsSentList(provider: provider),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
