class ServiceAnalyticsModel {
  final String serviceId;
  final String serviceName;
  final int totalBookings;
  final int completedBookings;
  final double revenue;
  final double shareOfTotalRevenue;
  final double averagePrice;

  const ServiceAnalyticsModel({
    required this.serviceId,
    required this.serviceName,
    required this.totalBookings,
    required this.completedBookings,
    required this.revenue,
    required this.shareOfTotalRevenue,
    required this.averagePrice,
  });
}
