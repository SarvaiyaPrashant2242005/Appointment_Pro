import '../../../bussiness_setup/data/models/business_model.dart';

class BookingSlugHelper {
  BookingSlugHelper._();

  /// The public booking domain for AppointmentPro.
  static const String publicBookingBaseUrl = 'https://appointment-pro.rishvi.app';

  /// Generates a clean, URL-safe slug from business name and ID.
  /// Example: "Apex Wellness Center" -> "apex-wellness-center-1791"
  static String generateSlug(BusinessModel business) {
    if (business.slug != null && business.slug!.trim().isNotEmpty) {
      return business.slug!.trim();
    }

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
  /// Normalizes any server host or local IP to the public production domain.
  static String buildBookingUrl(BusinessModel business) {
    final base = publicBookingBaseUrl.endsWith('/')
        ? publicBookingBaseUrl.substring(0, publicBookingBaseUrl.length - 1)
        : publicBookingBaseUrl;

    if (business.bookingUrl != null && business.bookingUrl!.trim().isNotEmpty) {
      final raw = business.bookingUrl!.trim();
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.path.isNotEmpty && uri.path != '/') {
        final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
        final query = uri.hasQuery ? '?${uri.query}' : '';
        return '$base$path$query';
      }
    }

    final slug = generateSlug(business);
    final businessId = business.id.trim();
    if (businessId.isNotEmpty) {
      return '$base/$slug/$businessId';
    }
    return '$base/$slug';
  }

  /// Checks if a business matches a requested slug or ID.
  static bool matchesSlugOrId(BusinessModel business, String query) {
    final q = query.trim().toLowerCase();
    if (business.id.toLowerCase() == q) return true;
    if (business.slug != null &&
        business.slug!.trim().isNotEmpty &&
        business.slug!.trim().toLowerCase() == q) {
      return true;
    }
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
