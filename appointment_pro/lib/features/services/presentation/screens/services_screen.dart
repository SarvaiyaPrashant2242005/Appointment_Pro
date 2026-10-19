import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/service_card.dart';
import '../widgets/service_form_sheet.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _filter = 'all'; // 'all', 'active', 'inactive'
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
      message:
          'Are you sure you want to delete "$name"? This cannot be undone.',
    );
    if (!confirmed) return;

    try {
      await ref.read(servicesProvider.notifier).deleteService(id);
      if (!mounted) return;
      AppToast.success(context, 'Service "$name" deleted.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to delete service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Services'),
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
        onPressed: () => showServiceFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
      ),
      body: servicesAsync.when(
        loading: () =>
            const Center(child: AppLoader(message: 'Loading services...')),
        error: (err, stack) => Center(
          child: AppErrorView(
            message: 'Unable to load services.',
            onRetry: () => ref.invalidate(servicesProvider),
          ),
        ),
        data: (allServices) {
          final filtered = allServices.where((s) {
            if (_filter == 'active' && !s.isActive) return false;
            if (_filter == 'inactive' && s.isActive) return false;
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final matchesName = s.name.toLowerCase().contains(query);
              final matchesDesc =
                  s.description?.toLowerCase().contains(query) ?? false;
              return matchesName || matchesDesc;
            }
            return true;
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Search & Filter Header
                  if (allServices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search services...',
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
                          const SizedBox(height: 8),

                          // Filter Segment / Chips
                          Row(
                            children: [
                              _buildFilterChip(
                                'all',
                                'All (${allServices.length})',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'active',
                                'Active (${allServices.where((s) => s.isActive).length})',
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'inactive',
                                'Inactive (${allServices.where((s) => !s.isActive).length})',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Content List or Empty State
                  Expanded(
                    child: allServices.isEmpty
                        ? Center(
                            child: AppEmptyView(
                              title: 'No Services Yet',
                              message:
                                  'Add the services your business offers to let customers book appointments.',
                              actionLabel: 'Add First Service',
                              icon: Icons.spa_outlined,
                              onAction: () => showServiceFormSheet(context),
                            ),
                          )
                        : filtered.isEmpty
                        ? Center(
                            child: AppEmptyView(
                              title: 'No Matching Services',
                              message:
                                  'Try adjusting your search query or filter.',
                              actionLabel: 'Clear Search',
                              icon: Icons.search_off_outlined,
                              onAction: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _filter = 'all';
                                });
                              },
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final service = filtered[index];
                              return ServiceCard(
                                service: service,
                                onEdit: () => showServiceFormSheet(
                                  context,
                                  initialService: service,
                                ),
                                onDelete: () =>
                                    _handleDelete(service.id, service.name),
                                onToggleStatus: (val) {
                                  ref
                                      .read(servicesProvider.notifier)
                                      .toggleStatus(service.id);
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? (isDark ? Colors.white : AppColors.primary)
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
