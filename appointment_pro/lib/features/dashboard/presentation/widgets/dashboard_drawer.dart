import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../bussiness_setup/presentation/widgets/business_form_sheet.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final business = ref.watch(activeBusinessProvider);

    final servicesCount = ref.watch(servicesProvider).asData?.value.length ?? 0;
    final staffCount = ref.watch(staffProvider).asData?.value.length ?? 0;
    final bookingsCount = ref.watch(todayBookingsProvider).length;
    final customersCount =
        ref.watch(customersProvider).asData?.value.length ?? 0;
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.accent,
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'AppointmentPro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                business?.name ?? 'Business Manager',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: business == null
                  ? null
                  : const Icon(Icons.swap_horiz_rounded),
              onTap: business == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.go(AppRouter.businessList);
                    },
            ),

            const Divider(height: 1),

            // Navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  const SizedBox(height: 12),
                  _section('BUSINESS'),

                  _tile(
                    context,
                    icon: Icons.storefront_outlined,
                    title: 'Manage Businesses',
                    onTap: () => _navigate(
                      context,
                      AppRouter.businessList,
                      replace: true,
                    ),
                  ),

                  _tile(
                    context,
                    icon: Icons.add_business_outlined,
                    title: 'Add New Business',
                    onTap: () {
                      Navigator.pop(context);
                      showBusinessFormSheet(context);
                    },
                  ),
                  const SizedBox(height: 12),

                  _section('MANAGEMENT'),

                  // _tile(
                  //   context,
                  //   icon: Icons.qr_code_2_rounded,
                  //   title: 'Share Booking Page & QR',
                  //   onTap: () => _navigate(context, AppRouter.shareBooking),
                  // ),
                  _tile(
                    context,
                    icon: Icons.design_services_outlined,
                    title: 'Services',
                    onTap: () => _navigate(context, AppRouter.services),
                  ),

                  _tile(
                    context,
                    icon: Icons.people_outline_rounded,
                    title: 'Staff Members',
                    onTap: () => _navigate(context, AppRouter.staff),
                  ),
                  _tile(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: 'Bookings & Appointments',
                    onTap: () => _navigate(context, AppRouter.bookings),
                  ),
                  _tile(
                    context,
                    icon: Icons.people_alt_outlined,
                    title: 'Customers & Clients',
                    onTap: () => _navigate(context, AppRouter.customers),
                  ),
                  _tile(
                    context,
                    icon: Icons.access_time_rounded,
                    title: 'Business Availability',
                    onTap: () => _navigate(context, AppRouter.availability),
                  ),
                  _tile(
                    context,
                    icon: Icons.insights_rounded,
                    title: 'Reports & Analytics',
                    onTap: () => _navigate(context, AppRouter.reports),
                  ),
                  const SizedBox(height: 12),

                  _section('GENERAL'),

                  _tile(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    badge: unreadNotifsCount,
                    onTap: () => _navigate(context, AppRouter.notifications),
                  ),
                  _tile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () =>
                        _navigate(context, AppRouter.settings, replace: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route, {bool replace = false}) {
    Navigator.pop(context);

    if (replace) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: badge != null && badge > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              child: Text(
                '$badge',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            )
          : null,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
