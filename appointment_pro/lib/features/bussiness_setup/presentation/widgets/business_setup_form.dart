import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/business_model.dart';

class BusinessSetupForm extends StatefulWidget {
  final Future<void> Function(BusinessModel business) onSubmit;
  final bool isLoading;

  const BusinessSetupForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<BusinessSetupForm> createState() => _BusinessSetupFormState();
}

class _BusinessSetupFormState extends State<BusinessSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _otherType = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  String _type = 'Salon / Beauty';
  String _countryCode = '+91';
  String? _logoPath;

  static const _types = [
    'Healthcare / Hospital',
    'Corporate',
    'Salon / Beauty',
    'Gym / Fitness',
    'Spa / Wellness',
    'Education / Coaching',
    'Professional Services',
    'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _otherType.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );

    if (image != null && mounted) {
      setState(() => _logoPath = image.path);
    }
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? '$label is required' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final business = BusinessModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      type: _type,
      otherType: _type == 'Other' ? _otherType.text.trim() : null,
      logoPath: _logoPath,
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      countryCode: _countryCode,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      createdAt: DateTime.now(),
    );

    await widget.onSubmit(business);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Upload
          Center(
            child: InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1.2,
                  ),
                  color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                ),
                clipBehavior: Clip.antiAlias,
                child: _logoPath == null
                    ? const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: AppColors.textSecondary,
                      )
                    : Image.file(
                        File(_logoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.business, size: 32),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Upload Business Logo (Optional)'),
            ),
          ),
          const SizedBox(height: 16),

          // Business Name (Required)
          AppTextField(
            label: 'Business Name',
            isRequired: true,
            hint: 'e.g. Apex Wellness Center',
            controller: _name,
            prefixIcon: const Icon(Icons.business_outlined),
            validator: (v) => _required(v, 'Business name'),
          ),
          const SizedBox(height: 16),

          // Business Type Dropdown (Required)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Business Type',
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  prefixIcon: IconTheme(
                    data: IconThemeData(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                    child: const Icon(Icons.category_outlined),
                  ),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
            ],
          ),

          if (_type == 'Other') ...[
            const SizedBox(height: 16),
            AppTextField(
              label: 'Specify Business Type',
              isRequired: true,
              hint: 'e.g. Photography Studio',
              controller: _otherType,
              validator: (v) =>
                  _type == 'Other' ? _required(v, 'Business type') : null,
            ),
          ],

          const SizedBox(height: 16),

          // Email Address (Optional)
          AppTextField(
            label: 'Email Address',
            isRequired: false,
            hint: 'business@example.com (Optional)',
            controller: _email,
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

          // Phone Number with Country Code (Optional)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Code Picker Box
                  Container(
                    width: 90,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _countryCode,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        dropdownColor:
                            isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        selectedItemBuilder: (context) {
                          return const [
                            Center(child: Text('+91')),
                            Center(child: Text('+1')),
                            Center(child: Text('+44')),
                            Center(child: Text('+971')),
                          ];
                        },
                        items: const [
                          DropdownMenuItem(
                            value: '+91',
                            child: Text('+91 (India)'),
                          ),
                          DropdownMenuItem(
                            value: '+1',
                            child: Text('+1 (USA)'),
                          ),
                          DropdownMenuItem(
                            value: '+44',
                            child: Text('+44 (UK)'),
                          ),
                          DropdownMenuItem(
                            value: '+971',
                            child: Text('+971 (UAE)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _countryCode = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Phone Number Input (Optional)
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          _countryCode == '+91' ? 10 : 15,
                        ),
                      ],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: _countryCode == '+91'
                            ? '10-digit number'
                            : 'Phone number',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        prefixIcon: IconTheme(
                          data: IconThemeData(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            size: 20,
                          ),
                          child: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (_countryCode == '+91' && digits.length != 10) {
                          return 'Enter a 10-digit phone number';
                        }
                        if (digits.length < 7 || digits.length > 15) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Submit Button
          AppButton(
            label: 'Save Business',
            onPressed: _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
