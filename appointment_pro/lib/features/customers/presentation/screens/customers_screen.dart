import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_form_sheet.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(CustomerModel customer) async {
    final confirmed = await AppConfirmDialog.showDelete(
      context,
      itemName: customer.name,
      message:
          'Are you sure you want to remove "${customer.name}" from your customer directory?',
    );
    if (!confirmed) return;

    try {
      await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
      if (!mounted) return;
      AppToast.success(context, 'Customer "${customer.name}" removed.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to remove customer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBusiness = ref.watch(activeBusinessProvider);
    final customersAsync = ref.watch(customersProvider);
    final filteredCustomers = ref.watch(filteredCustomersProvider);
    final currentFilter = ref.watch(customerFilterTypeProvider);
    final stats = ref.watch(customerStatsProvider);
    final searchQuery = ref.watch(customerSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customers & Clients',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (activeBusiness != null)
              Text(
                activeBusiness.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Customers',
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Customer',
            onPressed: () => showCustomerFormSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomerFormSheet(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer'),
      ),
      body: customersAsync.when(
        loading: () => const Center(
          child: AppLoader(message: 'Loading client directory...'),
        ),
        error: (err, stack) => Center(
          child: AppErrorView(
            message: 'Unable to load customers.',
            onRetry: () => ref.invalidate(customersProvider),
          ),
        ),
        data: (allCustomers) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // 1. KPI Summary Cards Strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        _KpiCard(
                          title: 'Total Clients',
                          count: '${stats['total']}',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'Returning',
                          count: '${stats['returning']}',
                          icon: Icons.repeat_rounded,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _KpiCard(
                          title: 'Appointments',
                          count: '${stats['totalBookings']}',
                          icon: Icons.event_available_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),

                  // 2. Search Box
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, email, notes...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        customerSearchQueryProvider.notifier,
                                      )
                                      .state = '';
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        ref
                            .read(customerSearchQueryProvider.notifier)
                            .state = val;
                      },
                    ),
                  ),

                  // 3. Segment Filter Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChipButton(
                          label: 'All (${allCustomers.length})',
                          isSelected:
                              currentFilter == CustomerFilterType.all,
                          onTap: () {
                            ref
                                .read(customerFilterTypeProvider.notifier)
                                .state = CustomerFilterType.all;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipButton(
                          label: 'Returning (${stats['returning']})',
                          isSelected:
                              currentFilter == CustomerFilterType.returning,
                          onTap: () {
                            ref
                                .read(customerFilterTypeProvider.notifier)
                                .state = CustomerFilterType.returning;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChipButton(
                          label:
                              'New (${stats['total']! - stats['returning']!})',
                          isSelected:
                              currentFilter == CustomerFilterType.newClients,
                          onTap: () {
                            ref
                                .read(customerFilterTypeProvider.notifier)
                                .state = CustomerFilterType.newClients;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 4. Customers List or Empty State
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(customersProvider.notifier).refresh(),
                      child: filteredCustomers.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 48,
                              ),
                              children: [
                                AppEmptyView(
                                  icon: searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.people_outline_rounded,
                                  title: searchQuery.isNotEmpty
                                      ? 'No Clients Found'
                                      : 'No Customers Yet',
                                  message: searchQuery.isNotEmpty
                                      ? 'No customers match "$searchQuery". Try searching by another keyword.'
                                      : 'Customers will automatically be saved when bookings are made, or you can add them manually now.',
                                  actionLabel: searchQuery.isNotEmpty
                                      ? 'Clear Search'
                                      : 'Add First Customer',
                                  onAction: () {
                                    if (searchQuery.isNotEmpty) {
                                      _searchController.clear();
                                      ref
                                          .read(
                                            customerSearchQueryProvider.notifier,
                                          )
                                          .state = '';
                                    } else {
                                      showCustomerFormSheet(context);
                                    }
                                  },
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 84,
                              ),
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return CustomerCard(
                                  customer: customer,
                                  onDelete: () => _handleDelete(customer),
                                );
                              },
                            ),
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

class _KpiCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.darkBorder : Colors.transparent),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
