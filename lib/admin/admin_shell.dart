// Signed in admin layout: sidebar, top bar, and the selected screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import 'admin_auth_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _select(int index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<_AdminDestination> destinations = <_AdminDestination>[
      _AdminDestination(
        label: l10n.adminDashboard,
        icon: Icons.dashboard_outlined,
      ),
      _AdminDestination(
        label: l10n.adminSettings,
        icon: Icons.settings_outlined,
      ),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          _Sidebar(
            destinations: destinations,
            selectedIndex: _index,
            onSelected: _select,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(title: destinations[_index].label),
                const Divider(),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: const <Widget>[
                      AdminDashboardScreen(),
                      AdminSettingsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sidebarWidth,
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              AppLocalizations.of(context).adminTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (int i = 0; i < destinations.length; i++)
            _SidebarItem(
              destination: destinations[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: Material(
        color: selected ? AppColors.sidebarActive : AppColors.sidebar,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: AppSizes.sidebarItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Icon(
                    destination.icon,
                    size: AppSizes.iconSm,
                    color: selected
                        ? AppColors.textInverse
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    destination.label,
                    style: AppTextStyles.label.copyWith(
                      color: selected
                          ? AppColors.textInverse
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final String? email = context.select<AdminAuthProvider, String?>(
      (AdminAuthProvider provider) => provider.email,
    );

    return Container(
      height: AppSizes.topBarHeight,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Text(title, style: AppTextStyles.titleSmall),
          const Spacer(),
          if (email != null)
            Text(email, style: AppTextStyles.bodySmall),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            onPressed: () => context.read<AdminAuthProvider>().signOut(),
            icon: const Icon(Icons.logout, size: AppSizes.iconSm),
          ),
        ],
      ),
    );
  }
}
