import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/service_form.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final String? serviceId;

  const ServiceFormScreen({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeBusinessId = ref.watch(activeBusinessIdProvider);
    final isEditing = widget.serviceId != null;

    if (activeBusinessId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Service' : 'Add Service')),
        body: Center(
          child: AppEmptyView(
            title: 'No Active Business',
            message: 'Please activate or set up a business first.',
            actionLabel: 'Go Back',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final initialService = isEditing
        ? ref.watch(serviceByIdProvider(widget.serviceId!))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Service' : 'Add Service')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ServiceForm(
                initialService: initialService,
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
                      AppToast.success(
                        context,
                        'Service updated successfully!',
                      );
                    } else {
                      await ref
                          .read(servicesProvider.notifier)
                          .createService(service);
                      if (!context.mounted) return;
                      AppToast.success(
                        context,
                        'Service created successfully!',
                      );
                    }
                    if (!context.mounted) return;
                    context.pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    final message = e is ApiException
                        ? e.messageToShow
                        : e is Exception
                            ? e.toString().replaceFirst('Exception: ', '')
                            : 'Unable to save service: ${e.toString()}';
                    AppToast.error(context, message);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
