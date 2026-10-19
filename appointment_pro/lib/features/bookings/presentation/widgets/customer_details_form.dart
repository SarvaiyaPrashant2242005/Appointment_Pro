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

  String _countryCode = '+91';

  final List<String> _commonCountryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+971',
    '+65',
    '+49',
    '+33',
    '+81',
    '+86',
    '+353',
  ];

  int get _maxPhoneDigits {
    switch (_countryCode) {
      case '+91':
      case '+1':
        return 10;
      case '+971':
        return 9;
      case '+65':
        return 8;
      case '+44':
      case '+61':
        return 11;
      default:
        return 15;
    }
  }

  String get _phoneHint {
    switch (_countryCode) {
      case '+91':
        return '9876543210 (10 digits)';
      case '+1':
        return '2025550143 (10 digits)';
      case '+971':
        return '501234567 (9 digits)';
      case '+65':
        return '81234567 (8 digits)';
      case '+44':
        return '7911123456';
      default:
        return 'Mobile number';
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
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
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter mobile phone number';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (_countryCode == '+91') {
      if (digits.length != 10) {
        return 'Indian mobile numbers must be 10 digits (${digits.length}/10 entered)';
      }
      if (!RegExp(r'^[6-9]').hasMatch(digits)) {
        return 'Indian numbers must start with 6, 7, 8, or 9';
      }
    } else if (_countryCode == '+1') {
      if (digits.length != 10) {
        return 'US/Canada number must be 10 digits (${digits.length}/10 entered)';
      }
      if (digits.startsWith('0') || digits.startsWith('1')) {
        return 'US/Canada numbers cannot start with 0 or 1';
      }
    } else if (_countryCode == '+971') {
      if (digits.length != 9) {
        return 'UAE numbers must be 9 digits (${digits.length}/9 entered)';
      }
    } else if (_countryCode == '+65') {
      if (digits.length != 8) {
        return 'Singapore numbers must be 8 digits (${digits.length}/8 entered)';
      }
      if (!RegExp(r'^[89]').hasMatch(digits)) {
        return 'Singapore numbers must start with 8 or 9';
      }
    } else {
      if (digits.length < 7 || digits.length > 15) {
        return 'Please enter between 7 and 15 digits';
      }
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _countryCode = widget.initialCountryCode.isNotEmpty
        ? widget.initialCountryCode
        : '+91';
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
      phone: _phoneController.text.replaceAll(RegExp(r'\D'), '').trim(),
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
            validator: _validateName,
          ),
          const SizedBox(height: 16),

          // Phone Number with Country Code
          Text.rich(
            TextSpan(
              text: 'Mobile Phone Number',
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
                        : '+91',
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
                        setState(() {
                          _countryCode = val;
                          final max = _maxPhoneDigits;
                          final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
                          if (digits.length > max) {
                            _phoneController.text = digits.substring(0, max);
                          }
                        });
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
                    LengthLimitingTextInputFormatter(_maxPhoneDigits),
                  ],
                  decoration: InputDecoration(
                    hintText: _phoneHint,
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
                  validator: _validatePhone,
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
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),

          // Customer Notes (optional)
          AppTextField(
            label: 'Special Requests or Notes (Optional)',
            hint: 'Any specific instructions or preferences...',
            controller: _notesController,
            keyboardType: TextInputType.multiline,
            maxLength: 500,
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
