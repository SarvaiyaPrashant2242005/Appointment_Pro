import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../data/models/staff_model.dart';

class StaffCard extends ConsumerWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStatus;

  const StaffCard({
    super.key,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final allServices = ref.watch(servicesProvider).value ?? [];

    // Find assigned service names
    final assignedServices = allServices
        .where((s) => staff.assignedServiceIds.contains(s.id))
        .toList();

    final initials = staff.name.trim().isNotEmpty
        ? staff.name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'S';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: staff.isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : (isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : const Color(0xFFE2E8F0)),
                backgroundImage:
                    staff.avatarPath != null &&
                        File(staff.avatarPath!).existsSync()
                    ? FileImage(File(staff.avatarPath!))
                    : null,
                child:
                    staff.avatarPath == null ||
                        !File(staff.avatarPath!).existsSync()
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: staff.isActive
                              ? AppColors.accent
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Staff Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: staff.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                              color: staff.isActive
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                        ),
                        // Active Switch
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: staff.isActive,
                            activeThumbColor: AppColors.accent,
                            onChanged: onToggleStatus,
                          ),
                        ),
                      ],
                    ),
                    if (staff.phone != null && staff.phone!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            staff.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (staff.email != null && staff.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              staff.email!,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Assigned Services Chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Services (${assignedServices.length}):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (assignedServices.isEmpty)
                      Text(
                        'No services assigned yet',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...assignedServices.take(3).map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                s.name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }),
                          if (assignedServices.length > 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${assignedServices.length - 3} more',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Edit & Delete Buttons
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Staff',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Delete Staff',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
