import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Full Name',
            hint: 'e.g. John Doe',
            controller: nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline),
            validator: Validators.validateFullName,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (v) => Validators.validateEmail(
              v,
              password: passwordController.text,
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Phone Number',
            hint: '10-digit mobile number',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_outlined),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Password',
            hint: 'Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special',
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) => Validators.validatePassword(
              v,
              email: emailController.text,
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: confirmPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) => Validators.validateConfirmPassword(
              v,
              passwordController.text,
            ),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Create Account',
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              GestureDetector(
                onTap: onLoginTap,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
