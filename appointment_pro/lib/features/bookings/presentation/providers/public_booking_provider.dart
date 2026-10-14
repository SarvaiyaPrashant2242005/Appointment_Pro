import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../availability/data/models/availability_model.dart';
import '../../../availability/presentation/providers/availability_provider.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../services/data/models/service_model.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/data/models/staff_model.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/booking_slot_model.dart';
import '../../data/utils/booking_availability_calculator.dart';
import '../../data/utils/booking_slug_helper.dart';
import 'booking_provider.dart';

/// Steps in the public booking wizard
enum PublicBookingStep {
  service,
  staff,
  dateTime,
  customerDetails,
  review,
  success,
}

/// State of the public customer booking flow
class PublicBookingState {
  final bool isLoading;
  final String? errorMessage;
  final BusinessModel? business;
  final List<ServiceModel> services;
  final List<StaffModel> allStaff;
  final BusinessAvailability? availability;
  final List<BookingModel> existingBookings;

  // Selections
  final PublicBookingStep currentStep;
  final ServiceModel? selectedService;
  final StaffModel? selectedStaff; // null = Any Available
  final DateTime selectedDate;
  final BookingSlot? selectedSlot;

  // Customer Details
  final String customerName;
  final String customerCountryCode;
  final String customerPhone;
  final String? customerEmail;
  final String? customerNotes;

  // Submission state
  final bool isSubmitting;
  final BookingModel? confirmedBooking;

  PublicBookingState({
    this.isLoading = true,
    this.errorMessage,
    this.business,
    this.services = const [],
    this.allStaff = const [],
    this.availability,
    this.existingBookings = const [],
    this.currentStep = PublicBookingStep.service,
    this.selectedService,
    this.selectedStaff,
    DateTime? selectedDate,
    this.selectedSlot,
    this.customerName = '',
    this.customerCountryCode = '+1',
    this.customerPhone = '',
    this.customerEmail,
    this.customerNotes,
    this.isSubmitting = false,
    this.confirmedBooking,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// Eligible staff for the selected service
  List<StaffModel> get eligibleStaff {
    if (selectedService == null) return [];
    return allStaff.where((s) {
      if (!s.isActive) return false;
      if (s.assignedServiceIds.isEmpty) return true;
      return s.assignedServiceIds.contains(selectedService!.id);
    }).toList();
  }

  /// Available slots computed for the selected date and service
  List<BookingSlot> get availableSlots {
    if (business == null || selectedService == null) return [];

    final avail = availability ?? BusinessAvailability.defaultFor(business!.id);

    return BookingAvailabilityCalculator.computeAvailableSlots(
      businessId: business!.id,
      service: selectedService!,
      date: selectedDate,
      selectedStaffId: selectedStaff?.id,
      businessAvailability: avail,
      eligibleStaff: eligibleStaff,
      existingBookings: existingBookings,
    );
  }

  PublicBookingState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    BusinessModel? business,
    List<ServiceModel>? services,
    List<StaffModel>? allStaff,
    BusinessAvailability? availability,
    List<BookingModel>? existingBookings,
    PublicBookingStep? currentStep,
    ServiceModel? selectedService,
    bool clearService = false,
    StaffModel? selectedStaff,
    bool clearStaff = false,
    DateTime? selectedDate,
    BookingSlot? selectedSlot,
    bool clearSlot = false,
    String? customerName,
    String? customerCountryCode,
    String? customerPhone,
    String? customerEmail,
    String? customerNotes,
    bool? isSubmitting,
    BookingModel? confirmedBooking,
  }) {
    return PublicBookingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      business: business ?? this.business,
      services: services ?? this.services,
      allStaff: allStaff ?? this.allStaff,
      availability: availability ?? this.availability,
      existingBookings: existingBookings ?? this.existingBookings,
      currentStep: currentStep ?? this.currentStep,
      selectedService: clearService
          ? null
          : (selectedService ?? this.selectedService),
      selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      customerName: customerName ?? this.customerName,
      customerCountryCode: customerCountryCode ?? this.customerCountryCode,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerNotes: customerNotes ?? this.customerNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
    );
  }
}

/// Controller managing public customer booking flow
final publicBookingProvider =
    NotifierProvider.autoDispose<PublicBookingNotifier, PublicBookingState>(
      PublicBookingNotifier.new,
    );

class PublicBookingNotifier extends Notifier<PublicBookingState> {
  String? _slugOrId;

  @override
  PublicBookingState build() {
    return PublicBookingState(isLoading: true);
  }

  Future<void> init(String slugOrId) async {
    _slugOrId = slugOrId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final businessRepo = ref.read(businessRepositoryProvider);
      final businesses = await businessRepo.getBusinesses();

      // Find matching business by slug or id
      final business = businesses.where((b) {
        return BookingSlugHelper.matchesSlugOrId(b, slugOrId);
      }).firstOrNull;

      if (business == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Business not found. Please check the booking link or contact the business.',
        );
        return;
      }

      // Load services, staff, availability, existing bookings for this business
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final staffRepo = ref.read(staffRepositoryProvider);
      final availabilityRepo = ref.read(availabilityRepositoryProvider);
      final bookingRepo = ref.read(bookingRepositoryProvider);

      final services = await serviceRepo.getServices(business.id);
      final activeServices = services.where((s) => s.isActive).toList();

      final staff = await staffRepo.getStaff(business.id);
      final activeStaff = staff.where((s) => s.isActive).toList();

      final avail = await availabilityRepo.getBusinessAvailability(business.id);
      final existingBookings = await bookingRepo.getBookings(business.id);

      state = state.copyWith(
        isLoading: false,
        business: business,
        services: activeServices,
        allStaff: activeStaff,
        availability: avail,
        existingBookings: existingBookings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load booking details: $e',
      );
    }
  }

  void selectService(ServiceModel service) {
    state = state.copyWith(
      selectedService: service,
      clearStaff: true,
      clearSlot: true,
      currentStep: PublicBookingStep.staff,
    );
  }

  void selectStaff(StaffModel? staff) {
    state = state.copyWith(
      selectedStaff: staff,
      clearStaff: staff == null,
      clearSlot: true,
      currentStep: PublicBookingStep.dateTime,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearSlot: true);
  }

  void selectSlot(BookingSlot slot) {
    state = state.copyWith(
      selectedSlot: slot,
      currentStep: PublicBookingStep.customerDetails,
    );
  }

  void setCustomerDetails({
    required String name,
    required String countryCode,
    required String phone,
    String? email,
    String? notes,
  }) {
    state = state.copyWith(
      customerName: name,
      customerCountryCode: countryCode,
      customerPhone: phone,
      customerEmail: email,
      customerNotes: notes,
      currentStep: PublicBookingStep.review,
    );
  }

  void goToStep(PublicBookingStep step) {
    state = state.copyWith(currentStep: step);
  }

  /// Submit the booking after performing slot revalidation and staff assignment
  Future<bool> submitBooking() async {
    if (state.business == null ||
        state.selectedService == null ||
        state.selectedSlot == null) {
      state = state.copyWith(
        errorMessage: 'Please complete all booking selections.',
      );
      return false;
    }

    if (state.customerName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your full name.');
      return false;
    }

    if (state.customerPhone.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid phone number.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final business = state.business!;
      final service = state.selectedService!;
      final slot = state.selectedSlot!;
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // 1. Refresh existing bookings from database to ensure fresh concurrency check
      final latestBookings = await bookingRepo.getBookings(business.id);

      // 2. Determine assigned staff member
      String assignedStaffId;
      if (state.selectedStaff != null) {
        assignedStaffId = state.selectedStaff!.id;
      } else {
        // Auto-assign from available staff for this slot
        final dayBookings = latestBookings.where((b) {
          return b.startAt.year == state.selectedDate.year &&
              b.startAt.month == state.selectedDate.month &&
              b.startAt.day == state.selectedDate.day;
        }).toList();

        final bestStaffId =
            BookingAvailabilityCalculator.selectBestStaffForSlot(
              availableStaffIds: slot.availableStaffIds,
              existingBookingsForDay: dayBookings,
            );

        if (bestStaffId == null) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage:
                'No staff member is available for this slot. Please choose another time.',
          );
          return false;
        }
        assignedStaffId = bestStaffId;
      }

      // 3. Revalidate slot availability immediately before saving
      final isAvailable = BookingAvailabilityCalculator.isSlotStillAvailable(
        startAt: slot.startAt,
        endAt: slot.endAt,
        bufferMinutes: service.bufferMinutes,
        staffId: assignedStaffId,
        existingBookings: latestBookings,
      );

      if (!isAvailable) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage:
              'This slot was just booked by another customer. Please select another time.',
        );
        return false;
      }

      // 4. Construct BookingModel
      final staffMember = state.selectedStaff ??
          state.allStaff.where((s) => s.id == assignedStaffId).firstOrNull;

      final bookingId = 'bk_${DateTime.now().millisecondsSinceEpoch}';
      final booking = BookingModel(
        id: bookingId,
        businessId: business.id,
        serviceId: service.id,
        serviceName: service.name,
        staffId: assignedStaffId,
        staffName: staffMember?.name,
        customerName: state.customerName.trim(),
        customerPhone: state.customerPhone.trim(),
        customerCountryCode: state.customerCountryCode.trim(),
        customerEmail: state.customerEmail?.trim().isEmpty == true
            ? null
            : state.customerEmail?.trim(),
        customerNotes: state.customerNotes?.trim().isEmpty == true
            ? null
            : state.customerNotes?.trim(),
        startAt: slot.startAt,
        endAt: slot.endAt,
        price: service.price,
        status: BookingStatus.confirmed, // public booking confirms immediately
        createdAt: DateTime.now(),
      );

      // 5. Persist booking
      final created = await bookingRepo.createBooking(booking);

      // 6. Notify owner bookings provider to refresh if loaded
      ref.read(bookingsProvider.notifier).refresh();

      state = state.copyWith(
        isSubmitting: false,
        confirmedBooking: created,
        currentStep: PublicBookingStep.success,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to complete booking: $e',
      );
      return false;
    }
  }

  void resetFlow() {
    if (_slugOrId != null) {
      init(_slugOrId!);
      return;
    }
    state = state.copyWith(
      currentStep: PublicBookingStep.service,
      clearService: true,
      clearStaff: true,
      clearSlot: true,
      customerName: '',
      customerPhone: '',
      customerEmail: null,
      customerNotes: null,
      isSubmitting: false,
      confirmedBooking: null,
      clearError: true,
    );
  }
}
