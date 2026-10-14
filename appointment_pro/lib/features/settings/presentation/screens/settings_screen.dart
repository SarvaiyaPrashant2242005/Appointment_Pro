import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../bussiness_setup/presentation/widgets/business_form_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Choose Theme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                ctx,
                title: 'Light Mode',
                subtitle: 'Clean and bright appearance',
                icon: Icons.light_mode_outlined,
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildThemeOption(
                ctx,
                title: 'Dark Mode',
                subtitle: 'Sleek and easy on the eyes',
                icon: Icons.dark_mode_outlined,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildThemeOption(
                ctx,
                title: 'System Default',
                subtitle: 'Follow device system settings',
                icon: Icons.brightness_auto_outlined,
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkInputFill : AppColors.inputFill),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accent
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                  size: 22,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final String themeSubtitle;
    final IconData themeIcon;
    switch (currentThemeMode) {
      case ThemeMode.light:
        themeSubtitle = 'Light Mode';
        themeIcon = Icons.light_mode_outlined;
        break;
      case ThemeMode.dark:
        themeSubtitle = 'Dark Mode';
        themeIcon = Icons.dark_mode_outlined;
        break;
      case ThemeMode.system:
        themeSubtitle = 'System Default';
        themeIcon = Icons.brightness_auto_outlined;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section: Business
          Text(
            'BUSINESS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Manage Businesses'),
                  subtitle: Text(
                    activeBusiness != null
                        ? 'Active: ${activeBusiness.name}'
                        : 'Configure or add businesses',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRouter.businessList),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.add_business_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Add New Business'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showBusinessFormSheet(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.design_services_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Services & Catalog'),
                  subtitle: const Text('Manage prices, duration & buffers'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.services),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.people_outline_rounded,
                    color: AppColors.accent,
                  ),
                  title: const Text('Staff Members'),
                  subtitle: const Text('Team profiles & service assignments'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.staff),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.accent,
                  ),
                  title: const Text('Hours & Availability'),
                  subtitle: const Text('Working hours, breaks & holidays'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.availability),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Preferences
          Text(
            'PREFERENCES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Notifications'),
                  subtitle: const Text('Reminders, bookings, updates'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(themeIcon, color: AppColors.accent),
                  title: const Text('Theme'),
                  subtitle: Text(themeSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showThemeDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: App Info
          Text(
            'ABOUT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.accent),
                  title: Text('AppointmentPro'),
                  subtitle: Text('Version 1.0.0+1'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Privacy & Terms'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
