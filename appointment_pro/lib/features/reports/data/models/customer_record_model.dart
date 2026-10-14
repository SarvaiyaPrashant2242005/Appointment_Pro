class CustomerRecordModel {
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalSpent;
  final DateTime firstVisit;
  final DateTime lastVisit;

  const CustomerRecordModel({
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSpent,
    required this.firstVisit,
    required this.lastVisit,
  });

  bool get isRepeatCustomer => totalBookings >= 2;
  double get averageSpend =>
      completedBookings > 0 ? (totalSpent / completedBookings) : 0.0;
}
