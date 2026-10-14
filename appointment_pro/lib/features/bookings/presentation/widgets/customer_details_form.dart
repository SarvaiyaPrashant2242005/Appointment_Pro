import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class CustomerDetailsForm extends StatefulWidget {
  final String initialName;
  final String initialCountryCode;
  final String initialPhone;
  final String? initialEmail;
  final String? initialNotes;
  final void Function({
    required String name,
    required String countryCode,
    required String phone,
    String? email,
    String? notes,
  })
  onSubmit;

  const CustomerDetailsForm({
    super.key,
    required this.initialName,
    required this.initialCountryCode,
    required this.initialPhone,
    this.initialEmail,
    this.initialNotes,
    required this.onSubmit,
  });

  @override
  State<CustomerDetailsForm> createState() => _CustomerDetailsFormState();
}

class _CustomerDetailsFormState extends State<CustomerDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  String _countryCode = '+1';

  final List<String> _commonCountryCodes = [
    '+1',
    '+44',
    '+91',
    '+61',
    '+49',
    '+33',
    '+81',
    '+86',
    '+971',
    '+353',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _countryCode = widget.initialCountryCode.isNotEmpty
        ? widget.initialCountryCode
        : '+1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      name: _nameController.text.trim(),
      countryCode: _countryCode,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Name
          AppTextField(
            label: 'Full Name',
            hint: 'e.g. Jane Doe',
            controller: _nameController,
            isRequired: true,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number with Country Code
          Text.rich(
            TextSpan(
              text: 'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code selector
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _commonCountryCodes.contains(_countryCode)
                        ? _countryCode
                        : '+1',
                    dropdownColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: _commonCountryCodes.map((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _countryCode = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Phone field
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  decoration: InputDecoration(
                    hintText: '555 123 4567',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkInputFill
                        : AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.trim().length < 6) {
                      return 'Enter at least 6 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email (optional)
          AppTextField(
            label: 'Email Address (Optional)',
            hint: 'e.g. jane@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Customer Notes (optional)
          AppTextField(
            label: 'Special Requests or Notes (Optional)',
            hint: 'Any specific instructions or preferences...',
            controller: _notesController,
            keyboardType: TextInputType.multiline,
            maxLength: 300,
            prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
          ),
          const SizedBox(height: 24),

          // Continue Button
          AppButton(
            label: 'Review Booking Details',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
