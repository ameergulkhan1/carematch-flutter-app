import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/client_user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  ClientUser? _clientUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole;
  String? _verificationStatus;

  User? get firebaseUser => _firebaseUser;
  User? get currentUser => _firebaseUser;
  ClientUser? get clientUser => _clientUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  String? get userRole => _userRole;
  String? get verificationStatus => _verificationStatus;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadClientUser(user.uid);
      } else {
        _clientUser = null;
      }
      notifyListeners();
    });
  }

  // Load client user data
  Future<void> _loadClientUser(String uid) async {
    _clientUser = await _authService.getClientUser(uid);
    notifyListeners();
  }

  // Register new client
  Future<bool> registerClient({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.registerClient(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
    );

    _isLoading = false;

    if (result['success']) {
      // User will be loaded automatically via auth state listener
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _userRole = null;
    _verificationStatus = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      // Store user role and verification status for navigation
      _userRole = result['role'] as String?;
      _verificationStatus = result['verificationStatus'] as String?;
      // User will be loaded automatically via auth state listener
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.sendPasswordResetEmail(email);

    _isLoading = false;

    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result['success'];
  }

  // Send password reset email (new simplified method)
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  // Send email verification to current user
  Future<void> sendEmailVerification() async {
    if (_firebaseUser != null && !_firebaseUser!.emailVerified) {
      await _firebaseUser!.sendEmailVerification();
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    if (_firebaseUser != null) {
      await _firebaseUser!.reload();
      _firebaseUser = FirebaseAuth.instance.currentUser;
      notifyListeners();
      return _firebaseUser?.emailVerified ?? false;
    }
    return false;
  }

  // Update client profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_firebaseUser == null) return false;

    _isLoading = true;
    notifyListeners();

    final success =
        await _authService.updateClientProfile(_firebaseUser!.uid, updates);

    if (success) {
      await _loadClientUser(_firebaseUser!.uid);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUser = null;
    _clientUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
