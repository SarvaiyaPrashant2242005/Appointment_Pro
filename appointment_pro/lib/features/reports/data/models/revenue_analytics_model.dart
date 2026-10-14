class RevenueChartPoint {
  final String label;
  final DateTime date;
  final double revenue;
  final int completedCount;

  const RevenueChartPoint({
    required this.label,
    required this.date,
    required this.revenue,
    required this.completedCount,
  });
}

class RevenueAnalyticsModel {
  final double grossRevenue;
  final double projectedRevenue;
  final double lostRevenue;
  final int completedCount;
  final int confirmedCount;
  final int cancelledCount;
  final int noShowCount;
  final int totalBookings;
  final double completionRate;
  final double cancellationRate;
  final double averageOrderValue;
  final List<RevenueChartPoint> chartPoints;

  const RevenueAnalyticsModel({
    required this.grossRevenue,
    required this.projectedRevenue,
    required this.lostRevenue,
    required this.completedCount,
    required this.confirmedCount,
    required this.cancelledCount,
    required this.noShowCount,
    required this.totalBookings,
    required this.completionRate,
    required this.cancellationRate,
    required this.averageOrderValue,
    required this.chartPoints,
  });

  factory RevenueAnalyticsModel.empty() {
    return const RevenueAnalyticsModel(
      grossRevenue: 0.0,
      projectedRevenue: 0.0,
      lostRevenue: 0.0,
      completedCount: 0,
      confirmedCount: 0,
      cancelledCount: 0,
      noShowCount: 0,
      totalBookings: 0,
      completionRate: 0.0,
      cancellationRate: 0.0,
      averageOrderValue: 0.0,
      chartPoints: [],
    );
  }
}
