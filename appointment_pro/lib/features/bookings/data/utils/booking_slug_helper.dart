import '../../../bussiness_setup/data/models/business_model.dart';

class BookingSlugHelper {
  BookingSlugHelper._();

  /// The public booking domain for AppointmentPro.
  /// Note: In the local prototype, customer public booking routes are previewed inside
  /// the app via GoRouter (/book/:businessSlug). A live public URL accessible
  /// without the app requires deploying a web frontend.
  static const String publicBookingBaseUrl = 'https://appointmentpro.app/book';

  /// Generates a clean, URL-safe slug from business name and ID.
  /// Example: "Apex Wellness Center" -> "apex-wellness-center-1791"
  static String generateSlug(BusinessModel business) {
    final cleanName = business.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    final namePart = cleanName.isEmpty ? 'business' : cleanName;

    // Use a short deterministic suffix from the business id (last 4 characters) to guarantee uniqueness
    final idSuffix = business.id.length > 4
        ? business.id.substring(business.id.length - 4)
        : business.id;

    return '$namePart-$idSuffix';
  }

  /// Builds the complete shareable booking URL for a business.
  /// Prioritizes the dynamic network URL from the backend server so QR scanning works across devices.
  static String buildBookingUrl(BusinessModel business) {
    if (business.bookingUrl != null && business.bookingUrl!.trim().isNotEmpty) {
      return business.bookingUrl!.trim();
    }
    final slug = generateSlug(business);
    return '$publicBookingBaseUrl/$slug';
  }

  /// Checks if a business matches a requested slug or ID.
  static bool matchesSlugOrId(BusinessModel business, String query) {
    final q = query.trim().toLowerCase();
    if (business.id.toLowerCase() == q) return true;
    if (generateSlug(business).toLowerCase() == q) return true;

    // Also match simple name slug without id suffix
    final simpleNameSlug = business.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    if (simpleNameSlug == q) return true;

    return false;
  }
}
