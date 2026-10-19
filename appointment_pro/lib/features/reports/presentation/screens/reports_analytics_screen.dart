import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/report_period.dart';
import '../providers/reports_provider.dart';
import '../widgets/analytics_kpi_card.dart';
import '../widgets/customer_insights_card.dart';
import '../widgets/export_report_sheet.dart';
import '../widgets/revenue_bar_chart.dart';
import '../widgets/service_performance_card.dart';
import '../widgets/staff_performance_card.dart';

class ReportsAnalyticsScreen extends ConsumerWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBusiness = ref.watch(activeBusinessProvider);
    final selectedPeriod = ref.watch(selectedReportPeriodProvider);

    final revenueAsync = ref.watch(revenueAnalyticsProvider);
    final serviceAsync = ref.watch(serviceAnalyticsProvider);
    final staffAsync = ref.watch(staffAnalyticsProvider);
    final customerAsync = ref.watch(customerRecordsProvider);

    if (activeBusiness == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports & Analytics')),
        body: const AppEmptyView(
          icon: Icons.storefront_outlined,
          title: 'No Active Business',
          message: 'Please create or select a business to inspect reports.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Download PDF Reports',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => ExportReportSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(revenueAnalyticsProvider);
          ref.invalidate(serviceAnalyticsProvider);
          ref.invalidate(staffAnalyticsProvider);
          ref.invalidate(customerRecordsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReportPeriod.values.map((period) {
                    final isSelected = selectedPeriod == period;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period.label),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(selectedReportPeriodProvider.notifier)
                                .setPeriod(period);
                          }
                        },
                        selectedColor:
                            AppColors.accent.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // KPI Metric Cards
              revenueAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: AppLoader(),
                  ),
                ),
                error: (err, _) => AppErrorView(
                  message: 'Failed to compute revenue metrics: $err',
                  onRetry: () => ref.invalidate(revenueAnalyticsProvider),
                ),
                data: (revenue) {
                  return Column(
                    children: [
                      // 2x2 KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: AnalyticsKpiCard(
                              title: 'Gross Revenue',
                              value: '₹${revenue.grossRevenue.toStringAsFixed(2)}',
                              subtitle: revenue.completedCount > 0
                                  ? 'Avg ₹${revenue.averageOrderValue.toStringAsFixed(2)} / visit'
                                  : 'No sales recorded',
                              icon: Icons.payments_rounded,
                              color: AppColors.success,
                              badgeText: '${revenue.completedCount} sales',
                              badgeColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnalyticsKpiCard(
                              title: 'Completed',
                              value: '${revenue.completedCount}',
                              subtitle:
                                  '${revenue.totalBookings} total booked',
                              icon: Icons.task_alt_rounded,
                              color: AppColors.accent,
                              badgeText:
                                  '${revenue.completionRate.toStringAsFixed(0)}% rate',
                              badgeColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AnalyticsKpiCard(
                              title: 'Projected Upcoming',
                              value:
                                  '₹${revenue.projectedRevenue.toStringAsFixed(2)}',
                              subtitle:
                                  '${revenue.confirmedCount} upcoming visits',
                              icon: Icons.upcoming_rounded,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnalyticsKpiCard(
                              title: 'Lost Revenue',
                              value: '₹${revenue.lostRevenue.toStringAsFixed(2)}',
                              subtitle:
                                  '${revenue.cancelledCount} cancelled, ${revenue.noShowCount} no-show',
                              icon: Icons.cancel_outlined,
                              color: AppColors.error,
                              badgeText:
                                  '${revenue.cancellationRate.toStringAsFixed(0)}% drop',
                              badgeColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Revenue Bar Chart
                      RevenueBarChart(
                        points: revenue.chartPoints,
                        totalRevenue: revenue.grossRevenue,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Service Performance Breakdown
              serviceAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (services) => ServicePerformanceCard(services: services),
              ),

              const SizedBox(height: 20),

              // Staff Performance Breakdown
              staffAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (staff) => StaffPerformanceCard(staffList: staff),
              ),

              const SizedBox(height: 20),

              // Customer Directory & Top Spend Insights
              customerAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
                data: (customers) => CustomerInsightsCard(customers: customers),
              ),

              const SizedBox(height: 24),

              // Fast Export Banner
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need official PDF reports?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Download appointments, customer records, and revenue summary PDFs.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => ExportReportSheet.show(context),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
