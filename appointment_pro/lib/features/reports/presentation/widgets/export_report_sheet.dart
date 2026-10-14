import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/report_period.dart';
import '../../data/utils/pdf_report_generator.dart';
import '../providers/reports_provider.dart';

enum ExportReportType {
  appointments,
  customers,
  revenueSummary;

  String get title {
    switch (this) {
      case ExportReportType.appointments:
        return 'Appointments Report (PDF)';
      case ExportReportType.customers:
        return 'Customer Directory (PDF)';
      case ExportReportType.revenueSummary:
        return 'Revenue & Financial Analytics (PDF)';
    }
  }

  String get description {
    switch (this) {
      case ExportReportType.appointments:
        return 'Official PDF with dates, services, prices in ₹, client details, and statuses.';
      case ExportReportType.customers:
        return 'Directory PDF with client contacts, total visits, and lifetime spend in ₹.';
      case ExportReportType.revenueSummary:
        return 'Executive PDF with revenue KPIs, completion rates, and service breakdowns.';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportReportType.appointments:
        return Icons.calendar_month_rounded;
      case ExportReportType.customers:
        return Icons.people_alt_rounded;
      case ExportReportType.revenueSummary:
        return Icons.insights_rounded;
    }
  }
}

class ExportReportSheet extends ConsumerStatefulWidget {
  const ExportReportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExportReportSheet(),
    );
  }

  @override
  ConsumerState<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends ConsumerState<ExportReportSheet> {
  ExportReportType _selectedType = ExportReportType.appointments;
  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  bool _isGenerating = false;

  Future<Uint8List> _generatePdfBytes() async {
    final business = ref.read(activeBusinessProvider);
    final businessId = business?.id ?? '';
    final repo = ref.read(reportsRepositoryProvider);

    switch (_selectedType) {
      case ExportReportType.appointments:
        final bookings = await repo.getBookingsForPeriod(
          businessId,
          _selectedPeriod,
        );
        return PdfReportGenerator.generateAppointmentsPdf(
          bookings: bookings,
          period: _selectedPeriod,
          business: business,
        );

      case ExportReportType.customers:
        final customers = await repo.computeCustomerRecords(businessId);
        return PdfReportGenerator.generateCustomerRecordsPdf(
          customers: customers,
          business: business,
        );

      case ExportReportType.revenueSummary:
        final analytics = await repo.computeRevenueAnalytics(
          businessId,
          _selectedPeriod,
        );
        final services = await repo.computeServiceAnalytics(
          businessId,
          _selectedPeriod,
        );
        final staff = await repo.computeStaffAnalytics(
          businessId,
          _selectedPeriod,
        );
        return PdfReportGenerator.generateRevenueSummaryPdf(
          analytics: analytics,
          services: services,
          staff: staff,
          period: _selectedPeriod,
          business: business,
        );
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isGenerating = true);

    try {
      final bytes = await _generatePdfBytes();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = '${_selectedType.name}_report_$dateStr.pdf';

      setState(() => _isGenerating = false);

      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: filename);
      if (mounted) {
        Navigator.of(context).pop();
        AppToast.success(context, 'PDF generated successfully!');
      }
    } on MissingPluginException {
      setState(() => _isGenerating = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.restart_alt_rounded, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Restart Required'),
              ],
            ),
            content: const Text(
              'A new native PDF printing plugin was added. '
              'Hot reload cannot register new native Android plugins.\n\n'
              'Please completely STOP (⏹) the running app and re-run it (▶️ flutter run) to compile the native print service.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        AppToast.error(context, 'PDF generation failed: $e');
      }
    }
  }

  Future<void> _handlePreviewPdf() async {
    setState(() => _isGenerating = true);

    try {
      final bytes = await _generatePdfBytes();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = '${_selectedType.name}_report_$dateStr.pdf';

      setState(() => _isGenerating = false);

      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: filename,
      );
    } on MissingPluginException {
      setState(() => _isGenerating = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.restart_alt_rounded, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Restart Required'),
              ],
            ),
            content: const Text(
              'A new native PDF printing plugin was added. '
              'Hot reload cannot register new native Android plugins.\n\n'
              'Please completely STOP (⏹) the running app and re-run it (▶️ flutter run) to compile the native print service.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        AppToast.error(context, 'PDF preview failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download PDF Reports',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Accurate reports in ₹ directly from Local Storage',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Report Type Selector
            Text(
              'Select Report Type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...ExportReportType.values.map((type) {
              final isSelected = _selectedType == type;

              return InkWell(
                onTap: () => setState(() => _selectedType = type),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : (isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        color: isSelected
                            ? AppColors.accent
                            : (isDark ? Colors.white60 : Colors.black54),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.accent
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.description,
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
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.accent : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Period Selector (for Appointments & Revenue)
            if (_selectedType != ExportReportType.customers) ...[
              Text(
                'Reporting Period',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ReportPeriod.values.map((p) {
                  final isSelected = _selectedPeriod == p;
                  return ChoiceChip(
                    label: Text(p.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedPeriod = p),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.accent
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Export Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _handlePreviewPdf,
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Preview / Print'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _isGenerating ? 'Generating...' : 'Download PDF',
                    icon: Icons.download_rounded,
                    isLoading: _isGenerating,
                    onPressed: _isGenerating ? null : _handleDownloadPdf,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
