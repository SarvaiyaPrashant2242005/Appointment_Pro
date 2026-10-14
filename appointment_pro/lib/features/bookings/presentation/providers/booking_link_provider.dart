import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_toast.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/utils/booking_slug_helper.dart';

/// Information regarding the shareable public booking link for the current business
class BookingLinkInfo {
  final BusinessModel? business;
  final String slug;
  final String url;
  final bool hasBusiness;

  const BookingLinkInfo({
    required this.business,
    required this.slug,
    required this.url,
    required this.hasBusiness,
  });

  factory BookingLinkInfo.empty() => const BookingLinkInfo(
    business: null,
    slug: '',
    url: '',
    hasBusiness: false,
  );
}

/// Provider exposing the booking link info for the currently active business
final bookingLinkProvider = Provider<BookingLinkInfo>((ref) {
  final business = ref.watch(activeBusinessProvider);
  if (business == null) {
    return BookingLinkInfo.empty();
  }

  final slug = BookingSlugHelper.generateSlug(business);
  final url = BookingSlugHelper.buildBookingUrl(business);

  return BookingLinkInfo(
    business: business,
    slug: slug,
    url: url,
    hasBusiness: true,
  );
});

/// Service class for copy & share actions
class BookingShareService {
  BookingShareService._();

  /// Copies the booking URL to clipboard with feedback
  static Future<bool> copyToClipboard(BuildContext context, String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        AppToast.success(context, 'Booking link copied to clipboard!');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to copy link to clipboard');
      }
      return false;
    }
  }
}
