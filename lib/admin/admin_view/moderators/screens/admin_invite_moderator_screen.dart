import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../communities/models/community.dart';
import '../../communities/provider/communities_provider.dart';
import '../provider/moderators_provider.dart';

class AdminInviteModeratorScreen extends StatefulWidget {
  const AdminInviteModeratorScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminInviteModeratorScreen> createState() =>
      _AdminInviteModeratorScreenState();
}

class _AdminInviteModeratorScreenState
    extends State<AdminInviteModeratorScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Set<String> _selectedCommunityIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunitiesProvider>().loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedCommunityIds.remove(id)) {
        _selectedCommunityIds.add(id);
      }
    });
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _snack('Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }
    if (_selectedCommunityIds.isEmpty) {
      _snack('Assign at least one community.');
      return;
    }

    final bool ok = await context.read<ModeratorsProvider>().inviteModerator(
          email: email,
          password: password,
          communityIds: _selectedCommunityIds.toList(),
        );

    if (!mounted) {
      return;
    }
    if (ok) {
      _snack('Invite sent to $email.');
      widget.onBack();
    } else {
      final ModeratorsProvider mods = context.read<ModeratorsProvider>();
      _snack(mods.error ?? 'Could not send the invite.');
      mods.clearError();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool inviting = context.select<ModeratorsProvider, bool>(
      (ModeratorsProvider p) => p.isInviting,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Moderators /',
                          style: TextStyle(
                            color: AppColors.adminTextMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invite moderator',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      onPressed: inviting ? () {} : widget.onBack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 440,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.adminSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.adminBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _FieldLabel('Work email'),
                    AppTextField(
                      controller: _emailController,
                      enabled: !inviting,
                      hintText: 'name@queerloop.app',
                      keyboardType: TextInputType.emailAddress,
                      fillColor: AppColors.adminSurfaceAlt,
                      prefixIcon: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.adminTextMuted, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Password'),
                    AppTextField(
                      controller: _passwordController,
                      enabled: !inviting,
                      hintText: 'At least 8 characters',
                      isPassword: true,
                      fillColor: AppColors.adminSurfaceAlt,
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.adminTextMuted, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Assign communities'),
                    _CommunityPicker(
                      selectedIds: _selectedCommunityIds,
                      onToggle: _toggle,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Cancel',
                            onPressed: inviting ? () {} : widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Send invite',
                            isLoading: inviting,
                            onPressed: inviting ? () {} : _submit,
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
      ),
    );
  }
}

class _CommunityPicker extends StatelessWidget {
  const _CommunityPicker({required this.selectedIds, required this.onToggle});

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (_, CommunitiesProvider provider, _) {
        if (provider.isLoading && provider.communities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.adminPink,
              ),
            ),
          );
        }
        if (provider.communities.isEmpty) {
          return const Text(
            'No communities available — create one first.',
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Community c in provider.communities)
              AppTagChip(
                label: c.name,
                isSelected: selectedIds.contains(c.id),
                onTap: () => onToggle(c.id),
              ),
          ],
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.adminTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
