import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/caregiver_user_model.dart';
import '../services/caregiver_service.dart';
import '../services/auth_service.dart';

class CaregiverProvider with ChangeNotifier {
  final CaregiverService _caregiverService = CaregiverService();
  final AuthService _authService = AuthService();

  CaregiverUser? _currentCaregiver;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _uploadedDocuments = {};
  final Map<String, double> _uploadProgress = {};

  CaregiverUser? get currentCaregiver => _currentCaregiver;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get uploadedDocuments => _uploadedDocuments;
  Map<String, double> get uploadProgress => _uploadProgress;

  /// Register caregiver
  Future<bool> registerCaregiver({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String address,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _caregiverService.registerCaregiver(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
      );

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send OTP for email verification
  Future<bool> sendOTP(String email, String fullName) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.sendOTPEmail(email, fullName);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.verifyOTP(email, otp);

    if (success) {
      // Mark email as verified
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _authService.markEmailAsVerified(user.uid);
        await _loadCurrentCaregiver();
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Update professional information
  Future<bool> updateProfessionalInfo({
    required String yearsOfExperience,
    required List<String> specializations,
    String? bio,
    List<String>? certifications,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    final success = await _caregiverService.updateProfessionalInfo(
      uid: user.uid,
      yearsOfExperience: yearsOfExperience,
      specializations: specializations,
      bio: bio,
      certifications: certifications,
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Upload document
  Future<bool> uploadDocument({
    required String documentType,
    required PlatformFile file,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _uploadProgress[documentType] = 0.0;
    notifyListeners();

    final result = await _caregiverService.uploadDocument(
      uid: user.uid,
      documentType: documentType,
      file: file,
    );

    if (result['success'] == true) {
      _uploadedDocuments[documentType] = result['filePath']; // Store file path instead of URL
      _uploadProgress[documentType] = 1.0;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _uploadProgress.remove(documentType);
      notifyListeners();
      return false;
    }
  }

  /// Delete uploaded document
  Future<bool> deleteDocument(String documentType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final success = await _caregiverService.deleteDocument(
      uid: user.uid,
      documentType: documentType,
    );

    if (success) {
      _uploadedDocuments.remove(documentType);
      notifyListeners();
    }

    return success;
  }

  /// Submit all documents for verification
  Future<bool> submitDocumentsForVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    final success = await _caregiverService.submitDocuments(user.uid);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Load current caregiver profile
  Future<void> _loadCurrentCaregiver() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _currentCaregiver = await _caregiverService.getCaregiverProfile(user.uid);
    if (_currentCaregiver != null) {
      _uploadedDocuments = Map<String, String>.from(_currentCaregiver!.documents);
    }
    notifyListeners();
  }

  /// Load caregiver on init
  Future<void> initialize() async {
    await _loadCurrentCaregiver();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
