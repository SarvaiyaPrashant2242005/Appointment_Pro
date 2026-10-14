import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/service_model.dart';
import '../providers/service_provider.dart';
import 'service_form.dart';

/// Opens the Service Add/Edit Form inside a modern modal bottom sheet.
Future<void> showServiceFormSheet(
  BuildContext context, {
  ServiceModel? initialService,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ServiceFormBottomSheet(initialService: initialService);
    },
  );
}

class _ServiceFormBottomSheet extends ConsumerStatefulWidget {
  final ServiceModel? initialService;

  const _ServiceFormBottomSheet({this.initialService});

  @override
  ConsumerState<_ServiceFormBottomSheet> createState() =>
      _ServiceFormBottomSheetState();
}

class _ServiceFormBottomSheetState
    extends ConsumerState<_ServiceFormBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBusinessId = ref.watch(activeBusinessIdProvider);
    final isEditing = widget.initialService != null;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Drag Handle & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing ? 'Edit Service' : 'Add New Service',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form Body (Scrollable)
                Flexible(
                  child: activeBusinessId == null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.business_outlined,
                                  size: 40,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active business selected.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: ServiceForm(
                            initialService: widget.initialService,
                            businessId: activeBusinessId,
                            isLoading: _isLoading,
                            onSubmit: (service) async {
                              setState(() => _isLoading = true);
                              try {
                                if (isEditing) {
                                  await ref
                                      .read(servicesProvider.notifier)
                                      .updateService(service);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  AppToast.success(
                                    context,
                                    'Service "${service.name}" updated.',
                                  );
                                } else {
                                  await ref
                                      .read(servicesProvider.notifier)
                                      .createService(service);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  AppToast.success(
                                    context,
                                    'Service "${service.name}" created.',
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                AppToast.error(
                                  context,
                                  'Unable to save service: ${e.toString()}',
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
