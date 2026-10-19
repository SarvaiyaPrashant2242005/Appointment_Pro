import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/business_model.dart';
import '../providers/business_provider.dart';
import '../widgets/business_form_sheet.dart';

class BusinessListScreen extends ConsumerWidget {
  const BusinessListScreen({super.key});

  Widget _buildLogo(BusinessModel business) {
    final fullUrl = business.fullLogoUrl;
    if (fullUrl != null && fullUrl.isNotEmpty) {
      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            fullUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.business, color: AppColors.accent),
          ),
        );
      }
      final file = File(fullUrl);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.business, color: AppColors.accent),
          ),
        );
      }
    }
    return const Icon(Icons.business, color: AppColors.accent);
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    BusinessModel business,
  ) async {
    final confirmed = await AppConfirmDialog.showDelete(
      context,
      itemName: business.name,
      message:
          'Are you sure you want to delete "${business.name}"? All associated services and bookings will be affected.',
    );

    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(businessProvider.notifier).deleteBusiness(business.id);
      if (!context.mounted) return;
      AppToast.success(context, '"${business.name}" deleted successfully.');
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException
          ? e.messageToShow
          : 'Unable to delete business. Please try again.';
      AppToast.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Businesses'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBusinessFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Business'),
      ),
      body: businesses.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading businesses...')),
        error: (err, stack) => Center(
          child: AppErrorView(
            message: err is ApiException
                ? err.messageToShow
                : 'Unable to load businesses.',
            onRetry: () => ref.read(businessProvider.notifier).refresh(),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(businessProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  AppEmptyView(
                    title: 'No Businesses Yet',
                    message:
                        'Add your business to start managing schedules, bookings, and services.',
                    actionLabel: 'Add Business',
                    icon: Icons.storefront_outlined,
                    onAction: () => showBusinessFormSheet(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(businessProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final business = items[index];

                return AppCard(
                  onTap: () =>
                      showBusinessFormSheet(context, initialBusiness: business),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      child: _buildLogo(business),
                    ),
                    title: Text(
                      business.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.type == 'Other'
                              ? (business.otherType ?? 'Other')
                              : business.type,
                        ),
                        if (business.email != null &&
                            business.email!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            business.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (business.isActive)
                          Container(
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
                        else
                          TextButton(
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
                              } catch (e) {
                                if (!context.mounted) return;
                                final msg = e is ApiException
                                    ? e.messageToShow
                                    : 'Unable to switch business.';
                                AppToast.error(context, msg);
                              }
                            },
                            child: const Text('Set Active'),
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          tooltip: 'Options',
                          onSelected: (val) {
                            if (val == 'edit') {
                              showBusinessFormSheet(
                                context,
                                initialBusiness: business,
                              );
                            } else if (val == 'delete') {
                              _handleDelete(context, ref, business);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Edit Business'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
