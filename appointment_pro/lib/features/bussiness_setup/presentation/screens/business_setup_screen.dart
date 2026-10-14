import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../providers/business_provider.dart';
import '../widgets/business_setup_form.dart';

class BusinessSetupScreen extends ConsumerWidget {
  final bool isMandatory;

  const BusinessSetupScreen({super.key, this.isMandatory = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet
        ? 32.0
        : (screenWidth < 360 ? 16.0 : 20.0);

    return PopScope(
      canPop: !isMandatory,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isMandatory) {
          final confirmed = await AppConfirmDialog.showExit(context);
          if (confirmed) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMandatory ? 'Setup Your Business' : 'Add Business'),
          centerTitle: true,
          automaticallyImplyLeading: !isMandatory,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isMandatory) ...[
                      Text(
                        'Welcome! Let\'s set up your first business to get started.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    BusinessSetupForm(
                      isLoading: state.isLoading,
                      onSubmit: (business) async {
                        try {
                          await ref
                              .read(businessProvider.notifier)
                              .createBusiness(business);

                          if (!context.mounted) return;

                          AppToast.success(
                            context,
                            isMandatory
                                ? 'Business profile set up successfully!'
                                : 'Business added successfully!',
                          );

                          if (isMandatory) {
                            context.go(AppRouter.dashboard);
                          } else {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRouter.businessList);
                            }
                          }
                        } catch (_) {
                          if (!context.mounted) return;

                          AppToast.error(
                            context,
                            'Unable to save business. Please try again.',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
