import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../provider/cotd_provider.dart';
import '../widgets/cotd_composer_card.dart';
import '../widgets/cotd_live_panel.dart';

class AdminConversationOverviewScreen extends StatefulWidget {
  const AdminConversationOverviewScreen({
    required this.onOpenHistory,
    required this.onPublished,
    super.key,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onPublished;

  @override
  State<AdminConversationOverviewScreen> createState() =>
      _AdminConversationOverviewScreenState();
}

class _AdminConversationOverviewScreenState
    extends State<AdminConversationOverviewScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CotdProvider>().loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final CotdProvider provider = context.read<CotdProvider>();
    final created = await provider.publishQuestion(_questionController.text);
    if (!mounted) {
      return;
    }
    if (created != null) {
      _questionController.clear();
      _snack('Published “${created.question}” to everyone.');
      widget.onPublished();
    } else {
      _snack(provider.historyError ?? 'Could not publish the question.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool publishing = context.select<CotdProvider, bool>(
      (CotdProvider p) => p.isPublishing,
    );

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Conversation of the day',
                      style: TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'History',
                      height: 44,
                      backgroundColor: AppColors.adminSurfaceAlt,
                      onPressed: publishing ? () {} : widget.onOpenHistory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 11,
                    child: CotdComposerCard(
                      controller: _questionController,
                      publishing: publishing,
                      onPublish: _publish,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(flex: 10, child: CotdLivePanel()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
