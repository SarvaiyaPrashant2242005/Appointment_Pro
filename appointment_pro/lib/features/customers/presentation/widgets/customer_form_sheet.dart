import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';

/// Opens the Add/Edit Customer modal bottom sheet
Future<void> showCustomerFormSheet(
  BuildContext context, {
  CustomerModel? initialCustomer,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _CustomerFormBottomSheet(initialCustomer: initialCustomer),
  );
}

class _CustomerFormBottomSheet extends ConsumerStatefulWidget {
  final CustomerModel? initialCustomer;

  const _CustomerFormBottomSheet({this.initialCustomer});

  @override
  ConsumerState<_CustomerFormBottomSheet> createState() =>
      _CustomerFormBottomSheetState();
}

class _CustomerFormBottomSheetState
    extends ConsumerState<_CustomerFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _countryCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialCustomer;
    _nameController = TextEditingController(text: init?.name ?? '');
    _countryCodeController =
        TextEditingController(text: init?.countryCode ?? '+91');
    _phoneController = TextEditingController(text: init?.phone ?? '');
    _emailController = TextEditingController(text: init?.email ?? '');
    _notesController = TextEditingController(text: init?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final activeBusinessId = ref.read(activeBusinessIdProvider);
    if (activeBusinessId == null) {
      AppToast.error(context, 'Please select an active business first');
      return;
    }

    setState(() => _isLoading = true);

    final isEditing = widget.initialCustomer != null;
    final name = _nameController.text.trim();
    final countryCode = _countryCodeController.text.trim().isEmpty
        ? '+91'
        : _countryCodeController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      if (isEditing) {
        final updated = widget.initialCustomer!.copyWith(
          name: name,
          countryCode: countryCode,
          phone: phone,
          email: email,
          notes: notes,
        );
        await ref.read(customersProvider.notifier).updateCustomer(updated);
        if (!mounted) return;
        AppToast.success(context, 'Customer "$name" updated successfully.');
      } else {
        final newCustomer = CustomerModel(
          id: '',
          businessId: activeBusinessId,
          name: name,
          countryCode: countryCode,
          phone: phone,
          email: email,
          notes: notes,
        );
        await ref.read(customersProvider.notifier).createCustomer(newCustomer);
        if (!mounted) return;
        AppToast.success(context, 'Customer "$name" added to your directory.');
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        AppToast.error(context, e.messageToShow);
      } else {
        AppToast.error(
          context,
          isEditing ? 'Failed to update customer.' : 'Failed to create customer.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialCustomer != null;

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
                // Top drag handle & header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isEditing
                                      ? Icons.edit_note_rounded
                                      : Icons.person_add_alt_1_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing ? 'Edit Customer' : 'Add New Customer',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form Fields Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          AppTextField(
                            controller: _nameController,
                            label: 'Customer Name',
                            hint: 'e.g. John Doe',
                            isRequired: true,
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Customer name is required';
                              }
                              final trimmed = val.trim();
                              if (trimmed.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              if (trimmed.length > 100) {
                                return 'Name cannot exceed 100 characters';
                              }
                              final nameRegex = RegExp(r"^[\p{L}\s.'-]+$", unicode: true);
                              if (!nameRegex.hasMatch(trimmed)) {
                                return 'Name should only contain letters, spaces, dots, or hyphens';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone with Country Code Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 90,
                                child: AppTextField(
                                  controller: _countryCodeController,
                                  label: 'Code',
                                  hint: '+91',
                                  isRequired: true,
                                  keyboardType: TextInputType.phone,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  hint: '9876543210',
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  keyboardType: TextInputType.phone,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    final digits = val.replaceAll(RegExp(r'\D'), '');
                                    final code = _countryCodeController.text.trim();
                                    if (code == '+91') {
                                      if (digits.length != 10) {
                                        return 'Indian number must be 10 digits (${digits.length}/10)';
                                      }
                                      if (!RegExp(r'^[6-9]').hasMatch(digits)) {
                                        return 'Must start with 6, 7, 8, or 9';
                                      }
                                    } else if (code == '+1') {
                                      if (digits.length != 10) {
                                        return 'US/Canada number must be 10 digits (${digits.length}/10)';
                                      }
                                      if (digits.startsWith('0') || digits.startsWith('1')) {
                                        return 'Cannot start with 0 or 1';
                                      }
                                    } else {
                                      if (digits.length < 7 || digits.length > 15) {
                                        return 'Enter between 7 and 15 digits';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Email (Optional)
                          AppTextField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            hint: 'client@example.com',
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(val.trim())) {
                                  return 'Enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Notes
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client Notes / Preferences (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'Special requests, preferences, allergies, or history...',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit Action Button
                          AppButton(
                            label: isEditing ? 'Save Changes' : 'Add Customer',
                            isLoading: _isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
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
