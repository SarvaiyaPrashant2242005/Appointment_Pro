import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/business_provider.dart';

class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.businessSetup),
        icon: const Icon(Icons.add),
        label: const Text('Add Business'),
      ),
      body: businesses.when(
        loading: () => const Center(
          child: AppLoader(message: 'Loading businesses...'),
        ),
        error: (err, stack) => Center(
          child: AppErrorView(
            message: 'Unable to load businesses.',
            onRetry: () => ref.invalidate(businessProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AppEmptyView(
                title: 'No Businesses Yet',
                message:
                    'Add your business to start managing schedules, bookings, and services.',
                actionLabel: 'Add Business',
                icon: Icons.storefront_outlined,
                onAction: () => context.push(AppRouter.businessSetup),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final business = items[index];

              return AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    child: business.logoPath != null
                        ? ClipOval(
                            child: Image.file(
                              File(business.logoPath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.business, color: AppColors.accent),
                            ),
                          )
                        : const Icon(Icons.business, color: AppColors.accent),
                  ),
                  title: Text(
                    business.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    business.type == 'Other'
                        ? (business.otherType ?? 'Other')
                        : business.type,
                  ),
                  trailing: business.isActive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(businessProvider.notifier)
                                  .setActiveBusiness(business.id);

                              if (!context.mounted) return;

                              AppToast.success(
                                context,
                                '${business.name} is now active.',
                              );
                            } catch (_) {
                              if (!context.mounted) return;

                              AppToast.error(
                                context,
                                'Unable to switch business.',
                              );
                            }
                          },
                          child: const Text('Set Active'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
