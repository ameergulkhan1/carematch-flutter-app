/// Dependency Injection Container
/// Uses get_it for service location
/// All services, repositories, and use cases are registered here
///
/// **USAGE IN YOUR CODE:**
///
/// ```dart
/// // 1. Import the service locator
/// import 'package:carematch_app/injection_container.dart';
///
/// // 2. Get any registered service
/// final authRepo = sl<AuthRepository>();
/// final bookingService = sl<EnhancedBookingService>();
/// final notificationService = sl<NotificationService>();
///
/// // 3. Use in constructors (dependency injection)
/// class MyService {
///   final AuthRepository authRepository;
///   MyService(this.authRepository);
/// }
///
/// // Then instantiate with:
/// final myService = MyService(sl<AuthRepository>());
/// ```
library;

import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Core
import 'core/utils/logger.dart';

// Auth Feature - Data
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';

// Auth Feature - Domain
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';

// Booking Feature - Data
import 'features/booking/data/datasources/booking_remote_datasource.dart';
import 'features/booking/data/repositories/booking_repository_impl.dart';

// Booking Feature - Domain
import 'features/booking/domain/repositories/booking_repository.dart';
import 'features/booking/domain/usecases/booking_usecases.dart';

// Services
import 'services/notification_service.dart';
import 'services/enhanced_booking_service.dart';
import 'services/caregiver_search_service.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  // ==================== CORE ====================

  // Logger
  sl.registerLazySingleton<AppLogger>(() => AppLogger());

  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // ==================== AUTH FEATURE ====================

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => RegisterClient(sl()));
  sl.registerLazySingleton(() => RegisterCaregiver(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmail(sl()));
  sl.registerLazySingleton(() => VerifyEmail(sl()));
  sl.registerLazySingleton(() => IsEmailVerified(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));
  sl.registerLazySingleton(() => WatchAuthStateChanges(sl()));
  sl.registerLazySingleton(() => Reauthenticate(sl()));

  // ==================== BOOKING FEATURE ====================

  // Data sources
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateBooking(sl()));
  sl.registerLazySingleton(() => GetBooking(sl()));
  sl.registerLazySingleton(() => GetClientBookings(sl()));
  sl.registerLazySingleton(() => GetCaregiverBookings(sl()));
  sl.registerLazySingleton(() => WatchClientBookings(sl()));
  sl.registerLazySingleton(() => WatchCaregiverBookings(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatus(sl()));
  sl.registerLazySingleton(() => CancelBooking(sl()));
  sl.registerLazySingleton(() => AcceptBooking(sl()));
  sl.registerLazySingleton(() => RejectBooking(sl()));
  sl.registerLazySingleton(() => StartSession(sl()));
  sl.registerLazySingleton(() => EndSession(sl()));
  sl.registerLazySingleton(() => CompleteBooking(sl()));
  sl.registerLazySingleton(() => RaiseDispute(sl()));
  sl.registerLazySingleton(() => ResolveDispute(sl()));
  sl.registerLazySingleton(() => RequestReschedule(sl()));
  sl.registerLazySingleton(() => GetBookingStats(sl()));

  // ==================== SERVICES ====================

  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<EnhancedBookingService>(
      () => EnhancedBookingService());
  sl.registerLazySingleton<CaregiverSearchService>(
      () => CaregiverSearchService());
}
