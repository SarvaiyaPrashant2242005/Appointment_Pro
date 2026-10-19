import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/revenue_analytics_model.dart';

class RevenueBarChart extends StatefulWidget {
  final List<RevenueChartPoint> points;
  final double totalRevenue;

  const RevenueBarChart({
    super.key,
    required this.points,
    required this.totalRevenue,
  });

  @override
  State<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<RevenueBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = widget.points.map((p) => p.revenue).fold(0.0, max);
    final effectiveMax = maxVal > 0 ? maxVal : 100.0;

    final selectedPoint = _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.points.length
        ? widget.points[_selectedIndex!]
        : null;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedPoint != null
                        ? '${selectedPoint.label}: ₹${selectedPoint.revenue.toStringAsFixed(2)} (${selectedPoint.completedCount} completed)'
                        : 'Tap a bar to inspect period volume',
                    style: TextStyle(
                      fontSize: 12,
                      color: selectedPoint != null
                          ? AppColors.accent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                      fontWeight: selectedPoint != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '₹${widget.totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart Canvas
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = ((constraints.maxWidth / widget.points.length) - 8)
                    .clamp(8.0, 36.0);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.points.length, (index) {
                    final point = widget.points[index];
                    final isSelected = _selectedIndex == index;
                    final ratio = (point.revenue / effectiveMax).clamp(0.04, 1.0);
                    final barHeight = ratio * 120.0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = isSelected ? null : index;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value above bar when selected
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '₹${point.revenue.toInt()}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // The Animated Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: barWidth,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : (point.revenue > 0
                                      ? (isDark
                                          ? AppColors.accent.withValues(alpha: 0.75)
                                          : AppColors.accent.withValues(alpha: 0.85))
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border)),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Label underneath
                          Text(
                            point.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
