/// Test helper for mocking and utilities
library;

import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Features
import 'package:carematch_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:carematch_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:carematch_app/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:carematch_app/features/booking/domain/repositories/booking_repository.dart';

// Core
import 'package:carematch_app/core/network/network_info.dart';
import 'package:carematch_app/core/network/api_client.dart';

// Generate mocks for testing
@GenerateMocks([
  // Firebase
  FirebaseAuth,
  FirebaseFirestore,
  FirebaseStorage,
  User,
  UserCredential,
  
  // Auth
  AuthRemoteDataSource,
  AuthRepository,
  
  // Booking
  BookingRemoteDataSource,
  BookingRepository,
  
  // Network
  NetworkInfo,
  ApiClient,
])
void main() {}
