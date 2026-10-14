import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../data/models/business_model.dart';
import '../providers/business_provider.dart';
import 'business_setup_form.dart';

/// Opens the Add/Edit Business form as a modern modal bottom sheet.
Future<void> showBusinessFormSheet(
  BuildContext context, {
  BusinessModel? initialBusiness,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _BusinessFormBottomSheet(initialBusiness: initialBusiness);
    },
  );
}

class _BusinessFormBottomSheet extends ConsumerStatefulWidget {
  final BusinessModel? initialBusiness;

  const _BusinessFormBottomSheet({this.initialBusiness});

  @override
  ConsumerState<_BusinessFormBottomSheet> createState() =>
      _BusinessFormBottomSheetState();
}

class _BusinessFormBottomSheetState
    extends ConsumerState<_BusinessFormBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialBusiness != null;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: maxHeight,
          ),
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
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing ? 'Edit Business' : 'Add New Business',
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
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: BusinessSetupForm(
                      initialBusiness: widget.initialBusiness,
                      isLoading: _isLoading,
                      onSubmit: (business) async {
                        setState(() => _isLoading = true);
                        try {
                          if (isEditing) {
                            await ref
                                .read(businessProvider.notifier)
                                  .updateBusiness(business);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            AppToast.success(
                              context,
                              'Business "${business.name}" updated.',
                            );
                          } else {
                            await ref
                                .read(businessProvider.notifier)
                                .createBusiness(business);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            AppToast.success(
                              context,
                              'Business "${business.name}" added.',
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          AppToast.error(
                            context,
                            'Unable to save business: ${e.toString()}',
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
