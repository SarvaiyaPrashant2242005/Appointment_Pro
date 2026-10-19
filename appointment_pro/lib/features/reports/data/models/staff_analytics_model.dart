class StaffAnalyticsModel {
  final String staffId;
  final String staffName;
  final int totalAppointments;
  final int completedAppointments;
  final double revenue;
  final double completionRate;

  const StaffAnalyticsModel({
    required this.staffId,
    required this.staffName,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.revenue,
    required this.completionRate,
  });
}
