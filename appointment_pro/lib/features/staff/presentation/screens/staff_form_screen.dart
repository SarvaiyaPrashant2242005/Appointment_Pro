import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/staff_provider.dart';
import '../widgets/staff_form.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  final String? staffId;

  const StaffFormScreen({super.key, this.staffId});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeBusinessId = ref.watch(activeBusinessIdProvider);
    final isEditing = widget.staffId != null;

    if (activeBusinessId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Staff Member' : 'Add Staff Member'),
        ),
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

    final initialStaff = isEditing
        ? ref.watch(staffByIdProvider(widget.staffId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Staff Member' : 'Add Staff Member'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: StaffForm(
                initialStaff: initialStaff,
                businessId: activeBusinessId,
                isLoading: _isLoading,
                onSubmit: (staff) async {
                  setState(() => _isLoading = true);
                  try {
                    if (isEditing) {
                      await ref.read(staffProvider.notifier).updateStaff(staff);
                      if (!context.mounted) return;
                      AppToast.success(
                        context,
                        'Staff member updated successfully!',
                      );
                    } else {
                      await ref.read(staffProvider.notifier).createStaff(staff);
                      if (!context.mounted) return;
                      AppToast.success(
                        context,
                        'Staff member added successfully!',
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
                            : 'Unable to save staff: ${e.toString()}';
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
