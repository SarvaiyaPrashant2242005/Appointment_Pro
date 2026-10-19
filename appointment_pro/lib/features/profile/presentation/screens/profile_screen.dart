import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/register_provider.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.showLogout(context);
    if (!confirmed) return;

    if (!context.mounted) return;
    final fcmToken = FcmService.instance.fcmToken;
    await ref.read(authRepositoryProvider).logout(fcmToken);
    ref.invalidate(businessProvider);

    if (!context.mounted) return;
    AppToast.info(context, 'Logged out successfully');
    context.go(AppRouter.login);
  }

  Future<void> _pickAndUploadAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(avatarPath: image.path);
      if (mounted) {
        setState(() {});
        AppToast.success(context, 'Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to update profile photo');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  ImageProvider? _resolveAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
    final path = avatarUrl.trim();
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('/')) {
      return NetworkImage('${ApiEndpoints.baseOrigin}$path');
    }
    return NetworkImage('${ApiEndpoints.baseOrigin}/$path');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = ref.read(localStorageServiceProvider);
    final businessesAsync = ref.watch(businessProvider);
    final activeBusiness = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: false),
      body: FutureBuilder<String?>(
        future: storage.getUserProfile(),
        builder: (context, snapshot) {
          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data != null) {
            try {
              userData = jsonDecode(snapshot.data!) as Map<String, dynamic>;
            } catch (_) {}
          }

          final fullName = userData['fullName'] as String? ?? 'User';
          final email = userData['email'] as String? ?? '';
          final phone = userData['phone'] as String? ?? '';
          final avatarUrl =
              (userData['avatarUrl'] ?? userData['avatar_url']) as String?;
          final avatarProvider = _resolveAvatarProvider(avatarUrl);

          final initials = fullName.trim().isNotEmpty
              ? fullName
                    .trim()
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase()
              : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Avatar & Name Card
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.accent.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage: avatarProvider,
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                  )
                                : (avatarProvider == null
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accent,
                                          ),
                                        )
                                      : null),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Account Information
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Full Name'),
                        subtitle: Text(fullName),
                      ),
                      if (email.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email Address'),
                          subtitle: Text(email),
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: const Text('Phone Number'),
                          subtitle: Text(phone),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Businesses Overview
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Businesses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRouter.businessList),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Businesses',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${businessesAsync.value?.length ?? 0}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Business',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeBusiness?.name ?? 'None',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Logout Button
                AppButton(
                  label: 'Log Out',
                  icon: Icons.logout_rounded,
                  isOutlined: true,
                  onPressed: () => _handleLogout(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
