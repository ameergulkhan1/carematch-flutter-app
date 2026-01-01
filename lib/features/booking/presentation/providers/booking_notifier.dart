import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/usecases/booking_usecases.dart';
import '../../../../core/errors/failures.dart';
import '../../../../injection_container.dart';

/// Booking State Management with Riverpod
/// 
/// **USAGE EXAMPLE IN SCREENS:**
/// 
/// ```dart
/// // 1. Import the provider
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import 'package:carematch_app/features/booking/presentation/providers/booking_notifier.dart';
/// 
/// // 2. Make your screen a ConsumerWidget
/// class MyBookingsScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // 3. Watch the booking state
///     final bookingState = ref.watch(bookingProvider);
///     
///     // 4. Display bookings
///     return ListView.builder(
///       itemCount: bookingState.bookings.length,
///       itemBuilder: (context, index) {
///         final booking = bookingState.bookings[index];
///         return ListTile(
///           title: Text(booking.serviceType),
///           onTap: () {
///             // 5. Call methods from the notifier
///             ref.read(bookingProvider.notifier).getBooking(booking.id);
///           },
///         );
///       },
///     );
///   }
/// }
/// ```

/// Booking state
class BookingState {
  final List<BookingEntity> bookings;
  final BookingEntity? currentBooking;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final Failure? error;

  const BookingState({
    this.bookings = const [],
    this.currentBooking,
    this.stats,
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    List<BookingEntity>? bookings,
    BookingEntity? currentBooking,
    Map<String, dynamic>? stats,
    bool? isLoading,
    Failure? error,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      currentBooking: currentBooking ?? this.currentBooking,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Booking provider using Riverpod
class BookingNotifier extends StateNotifier<BookingState> {
  final CreateBooking _createBooking;
  final GetBooking _getBooking;
  final GetClientBookings _getClientBookings;
  final GetCaregiverBookings _getCaregiverBookings;
  final UpdateBookingStatus _updateBookingStatus;
  final CancelBooking _cancelBooking;
  final AcceptBooking _acceptBooking;
  final RejectBooking _rejectBooking;
  final StartSession _startSession;
  final EndSession _endSession;
  final CompleteBooking _completeBooking;
  final RaiseDispute _raiseDispute;
  final GetBookingStats _getBookingStats;

  BookingNotifier({
    required CreateBooking createBooking,
    required GetBooking getBooking,
    required GetClientBookings getClientBookings,
    required GetCaregiverBookings getCaregiverBookings,
    required UpdateBookingStatus updateBookingStatus,
    required CancelBooking cancelBooking,
    required AcceptBooking acceptBooking,
    required RejectBooking rejectBooking,
    required StartSession startSession,
    required EndSession endSession,
    required CompleteBooking completeBooking,
    required RaiseDispute raiseDispute,
    required GetBookingStats getBookingStats,
  })  : _createBooking = createBooking,
        _getBooking = getBooking,
        _getClientBookings = getClientBookings,
        _getCaregiverBookings = getCaregiverBookings,
        _updateBookingStatus = updateBookingStatus,
        _cancelBooking = cancelBooking,
        _acceptBooking = acceptBooking,
        _rejectBooking = rejectBooking,
        _startSession = startSession,
        _endSession = endSession,
        _completeBooking = completeBooking,
        _raiseDispute = raiseDispute,
        _getBookingStats = getBookingStats,
        super(const BookingState());

  /// Create new booking
  Future<bool> createBooking(CreateBookingParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createBooking(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Get single booking
  Future<void> getBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getBooking(bookingId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (booking) => state = state.copyWith(
        currentBooking: booking,
        isLoading: false,
      ),
    );
  }

  /// Get client bookings
  Future<void> getClientBookings(String clientId, {BookingStatus? statusFilter}) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = GetClientBookingsParams(
      clientId: clientId,
      statusFilter: statusFilter,
    );
    final result = await _getClientBookings(params);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (bookings) => state = state.copyWith(
        bookings: bookings,
        isLoading: false,
      ),
    );
  }

  /// Get caregiver bookings
  Future<void> getCaregiverBookings(String caregiverId, {BookingStatus? statusFilter}) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = GetCaregiverBookingsParams(
      caregiverId: caregiverId,
      statusFilter: statusFilter,
    );
    final result = await _getCaregiverBookings(params);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (bookings) => state = state.copyWith(
        bookings: bookings,
        isLoading: false,
      ),
    );
  }

  /// Update booking status
  Future<bool> updateBookingStatus(UpdateBookingStatusParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateBookingStatus(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = CancelBookingParams(
      bookingId: bookingId,
      reason: reason,
    );
    final result = await _cancelBooking(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Accept booking
  Future<bool> acceptBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _acceptBooking(bookingId);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Reject booking
  Future<bool> rejectBooking(String bookingId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = RejectBookingParams(
      bookingId: bookingId,
      reason: reason,
    );
    final result = await _rejectBooking(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Start session
  Future<bool> startSession(StartSessionParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _startSession(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// End session
  Future<bool> endSession(EndSessionParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _endSession(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Complete booking
  Future<bool> completeBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _completeBooking(bookingId);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Raise dispute
  Future<bool> raiseDispute(String bookingId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = RaiseDisputeParams(
      bookingId: bookingId,
      reason: reason,
    );
    final result = await _raiseDispute(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (booking) {
        state = state.copyWith(
          currentBooking: booking,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Get booking statistics
  Future<void> getBookingStats(String userId, String userType) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = GetBookingStatsParams(
      userId: userId,
      userType: userType,
    );
    final result = await _getBookingStats(params);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (stats) => state = state.copyWith(
        stats: stats,
        isLoading: false,
      ),
    );
  }
}

/// Booking provider
final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(
    createBooking: sl<CreateBooking>(),
    getBooking: sl<GetBooking>(),
    getClientBookings: sl<GetClientBookings>(),
    getCaregiverBookings: sl<GetCaregiverBookings>(),
    updateBookingStatus: sl<UpdateBookingStatus>(),
    cancelBooking: sl<CancelBooking>(),
    acceptBooking: sl<AcceptBooking>(),
    rejectBooking: sl<RejectBooking>(),
    startSession: sl<StartSession>(),
    endSession: sl<EndSession>(),
    completeBooking: sl<CompleteBooking>(),
    raiseDispute: sl<RaiseDispute>(),
    getBookingStats: sl<GetBookingStats>(),
  );
});
