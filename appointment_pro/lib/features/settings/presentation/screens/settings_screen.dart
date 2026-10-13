import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeBusiness = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
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
                  leading: const Icon(Icons.storefront_outlined, color: AppColors.accent),
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
                  leading: const Icon(Icons.add_business_outlined, color: AppColors.accent),
                  title: const Text('Add New Business'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRouter.businessSetup),
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
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.accent),
                  title: const Text('Notifications'),
                  subtitle: const Text('Reminders, bookings, updates'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Placeholder for notifications settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppColors.accent),
                  title: const Text('Theme'),
                  subtitle: Text(
                    theme.brightness == Brightness.dark ? 'Dark Mode' : 'Light Mode',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Theme switcher dialog or setting
                  },
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
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.accent),
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
