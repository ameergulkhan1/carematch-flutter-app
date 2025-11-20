import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/caregiver_user_model.dart';

class CaregiverSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search caregivers with filters
  Future<List<CaregiverUser>> searchCaregivers({
    List<String>? services,
    double? minRate,
    double? maxRate,
    int? minExperience,
    List<String>? languages,
    String? city,
    double? minRating,
    bool? isVerified,
  }) async {
    try {
      Query query = _firestore.collection('users').where('role', isEqualTo: 'caregiver');

      // Only verified caregivers
      if (isVerified == true) {
        query = query.where('verificationStatus', isEqualTo: 'approved');
      }

      // Get all documents first, then filter in memory
      // (Firestore has limitations on compound queries)
      final snapshot = await query.get();
      
      List<CaregiverUser> caregivers = snapshot.docs.map((doc) {
        return CaregiverUser.fromFirestore(doc);
      }).toList();

      // Apply filters in memory
      caregivers = caregivers.where((caregiver) {
        // Service filter (using specializations)
        if (services != null && services.isNotEmpty) {
          if (!services.any((service) => caregiver.specializations.contains(service))) {
            return false;
          }
        }

        // Rate filter (CaregiverUser doesn't have hourlyRate, skip for now)
        // TODO: Add hourlyRate field to CaregiverUser model
        // if (minRate != null && caregiver.hourlyRate < minRate) {
        //   return false;
        // }
        // if (maxRate != null && caregiver.hourlyRate > maxRate) {
        //   return false;
        // }

        // Experience filter
        if (minExperience != null && caregiver.yearsOfExperience != null) {
          final experience = int.tryParse(caregiver.yearsOfExperience!) ?? 0;
          if (experience < minExperience) {
            return false;
          }
        }

        // Language filter (CaregiverUser doesn't have languages field)
        // TODO: Add languages field to CaregiverUser model
        // if (languages != null && languages.isNotEmpty) {
        //   if (!languages.any((lang) => caregiver.languages.contains(lang))) {
        //     return false;
        //   }
        // }

        // City filter
        if (city != null && city.isNotEmpty) {
          if (caregiver.city.toLowerCase() != city.toLowerCase()) {
            return false;
          }
        }

        // Rating filter (CaregiverUser doesn't have rating field)
        // TODO: Calculate rating from reviews or add to model
        // if (minRating != null && caregiver.rating < minRating) {
        //   return false;
        // }

        return true;
      }).toList();

      // Sort by verification status (approved first)
      caregivers.sort((a, b) {
        if (a.verificationStatus == 'approved' && b.verificationStatus != 'approved') return -1;
        if (b.verificationStatus == 'approved' && a.verificationStatus != 'approved') return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return caregivers;
    } catch (e) {
      print('Error searching caregivers: $e');
      return [];
    }
  }

  // Get all verified caregivers
  Future<List<CaregiverUser>> getVerifiedCaregivers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'caregiver')
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      return snapshot.docs.map((doc) {
        return CaregiverUser.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting verified caregivers: $e');
      return [];
    }
  }

  // Get caregiver by ID
  Future<CaregiverUser?> getCaregiverById(String caregiverId) async {
    try {
      final doc = await _firestore.collection('users').doc(caregiverId).get();
      if (doc.exists) {
        return CaregiverUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting caregiver: $e');
      return null;
    }
  }

  // Get top-rated caregivers
  Future<List<CaregiverUser>> getTopRatedCaregivers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'caregiver')
          .where('verificationStatus', isEqualTo: 'approved')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return CaregiverUser.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting top-rated caregivers: $e');
      return [];
    }
  }

  // Get caregivers by service
  Future<List<CaregiverUser>> getCaregiversByService(String service) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'caregiver')
          .where('specializations', arrayContains: service)
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      return snapshot.docs.map((doc) {
        return CaregiverUser.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting caregivers by service: $e');
      return [];
    }
  }

  // Save/favorite a caregiver
  Future<bool> saveCaregiverToFavorites(String clientId, String caregiverId) async {
    try {
      await _firestore.collection('users').doc(clientId).collection('favorites').doc(caregiverId).set({
        'caregiverId': caregiverId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving caregiver to favorites: $e');
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeCaregiverFromFavorites(String clientId, String caregiverId) async {
    try {
      await _firestore.collection('users').doc(clientId).collection('favorites').doc(caregiverId).delete();
      return true;
    } catch (e) {
      print('Error removing caregiver from favorites: $e');
      return false;
    }
  }

  // Check if caregiver is favorited
  Future<bool> isCaregiverFavorited(String clientId, String caregiverId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(clientId)
          .collection('favorites')
          .doc(caregiverId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get favorite caregivers
  Future<List<CaregiverUser>> getFavoriteCaregivers(String clientId) async {
    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(clientId)
          .collection('favorites')
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        return [];
      }

      final caregiverIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      
      List<CaregiverUser> caregivers = [];
      
      for (String id in caregiverIds) {
        final caregiver = await getCaregiverById(id);
        if (caregiver != null) {
          caregivers.add(caregiver);
        }
      }

      return caregivers;
    } catch (e) {
      print('Error getting favorite caregivers: $e');
      return [];
    }
  }

  // Get available services (distinct list)
  Future<List<String>> getAvailableServices() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'caregiver')
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      Set<String> services = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['specializations'] != null) {
          services.addAll(List<String>.from(data['specializations']));
        }
      }

      return services.toList()..sort();
    } catch (e) {
      print('Error getting available services: $e');
      return [];
    }
  }
}
