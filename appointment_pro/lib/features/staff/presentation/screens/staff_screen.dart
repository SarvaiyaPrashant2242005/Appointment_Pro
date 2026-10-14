import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/staff_provider.dart';
import '../widgets/staff_card.dart';
import '../widgets/staff_form_sheet.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(String id, String name) async {
    final confirmed = await AppConfirmDialog.showDelete(
      context,
      itemName: name,
      message: 'Are you sure you want to remove "$name"?',
    );
    if (!confirmed) return;

    try {
      await ref.read(staffProvider.notifier).deleteStaff(id);
      if (!mounted) return;
      AppToast.success(context, 'Staff member "$name" removed.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to remove staff member.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Members'),
            if (activeBusiness != null)
              Text(
                activeBusiness.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStaffFormSheet(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
      ),
      body: staffAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading staff members...')),
        error: (err, stack) => Center(
          child: AppErrorView(
            message: 'Unable to load staff members.',
            onRetry: () => ref.invalidate(staffProvider),
          ),
        ),
        data: (staffList) {
          final filtered = staffList.where((st) {
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesName = st.name.toLowerCase().contains(query);
              final matchesEmail =
                  st.email?.toLowerCase().contains(query) ?? false;
              final matchesPhone = st.phone?.contains(query) ?? false;
              return matchesName || matchesEmail || matchesPhone;
            }
            return true;
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Search Box
                  if (staffList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search staff by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),

                  // Content List or Empty State
                  Expanded(
                    child: staffList.isEmpty
                        ? Center(
                            child: AppEmptyView(
                              title: 'No Staff Added Yet',
                              message:
                                  'Add your team members to assign services and manage appointment schedules.',
                              actionLabel: 'Add First Staff Member',
                              icon: Icons.people_outline,
                              onAction: () => showStaffFormSheet(context),
                            ),
                          )
                        : filtered.isEmpty
                        ? Center(
                            child: AppEmptyView(
                              title: 'No Matching Staff',
                              message: 'Try adjusting your search query.',
                              actionLabel: 'Clear Search',
                              icon: Icons.search_off_outlined,
                              onAction: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final staff = filtered[index];
                              return StaffCard(
                                staff: staff,
                                onEdit: () => showStaffFormSheet(
                                  context,
                                  initialStaff: staff,
                                ),
                                onDelete: () =>
                                    _handleDelete(staff.id, staff.name),
                                onToggleStatus: (val) {
                                  ref
                                      .read(staffProvider.notifier)
                                      .toggleStatus(staff.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
