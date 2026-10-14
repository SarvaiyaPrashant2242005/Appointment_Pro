import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../services/presentation/widgets/service_form_sheet.dart';
import '../../data/models/staff_model.dart';

class StaffForm extends ConsumerStatefulWidget {
  final StaffModel? initialStaff;
  final String businessId;
  final Future<void> Function(StaffModel staff) onSubmit;
  final bool isLoading;

  const StaffForm({
    super.key,
    this.initialStaff,
    required this.businessId,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  ConsumerState<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<StaffForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _avatarPath;
  late List<String> _selectedServiceIds;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final st = widget.initialStaff;
    _nameController = TextEditingController(text: st?.name ?? '');
    _emailController = TextEditingController(text: st?.email ?? '');
    _phoneController = TextEditingController(text: st?.phone ?? '');
    _avatarPath = st?.avatarPath;
    _selectedServiceIds = List<String>.from(st?.assignedServiceIds ?? []);
    _isActive = st?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image != null && mounted) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final now = DateTime.now();
    final staff = StaffModel(
      id:
          widget.initialStaff?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      businessId: widget.businessId,
      name: name,
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
      avatarPath: _avatarPath,
      assignedServiceIds: _selectedServiceIds,
      schedule: widget.initialStaff?.schedule,
      isActive: _isActive,
      createdAt: widget.initialStaff?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.onSubmit(staff);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final servicesAsync = ref.watch(servicesProvider);
    final services = servicesAsync.value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar Picker
          Center(
            child: InkWell(
              onTap: _pickAvatar,
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.inputFill,
                    backgroundImage:
                        _avatarPath != null && File(_avatarPath!).existsSync()
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child:
                        _avatarPath == null || !File(_avatarPath!).existsSync()
                        ? const Icon(
                            Icons.person_add_outlined,
                            size: 32,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _pickAvatar,
              child: const Text('Change Photo (Optional)'),
            ),
          ),
          const SizedBox(height: 16),

          // Full Name
          AppTextField(
            label: 'Full Name',
            isRequired: true,
            hint: 'e.g. Dr. Sarah Jenkins, Alex Rivera',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Full name is required';
              }
              if (v.trim().length < 2) {
                return 'Full name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email (Optional)
          AppTextField(
            label: 'Email Address',
            isRequired: false,
            hint: 'staff@example.com (Optional)',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                  ? null
                  : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 16),

          // Phone (Optional)
          AppTextField(
            label: 'Phone Number',
            isRequired: false,
            hint: '10-digit number (Optional)',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final digits = v.replaceAll(RegExp(r'\D'), '');
              return digits.length >= 7 && digits.length <= 15
                  ? null
                  : 'Enter a valid phone number';
            },
          ),
          const SizedBox(height: 20),

          // Assigned Services Multi-Select
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Services (${_selectedServiceIds.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (services.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_selectedServiceIds.length == services.length) {
                            _selectedServiceIds.clear();
                          } else {
                            _selectedServiceIds = services
                                .map((s) => s.id)
                                .toList();
                          }
                        });
                      },
                      child: Text(
                        _selectedServiceIds.length == services.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (services.isEmpty) ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No services created for this business yet.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => showServiceFormSheet(context),
                        child: const Text('Add Service'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services.map((s) {
                    final isSelected = _selectedServiceIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.name),
                      selected: isSelected,
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accent
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.primary)
                            : colorScheme.onSurface,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServiceIds.add(s.id);
                          } else {
                            _selectedServiceIds.remove(s.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Active / Inactive Card
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Member Active',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isActive
                          ? 'Available to take appointments'
                          : 'Unavailable / On leave',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isActive,
                  activeThumbColor: AppColors.accent,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Save Button
          AppButton(
            label: widget.initialStaff != null
                ? 'Update Staff Member'
                : 'Save Staff Member',
            onPressed: _handleSubmit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
