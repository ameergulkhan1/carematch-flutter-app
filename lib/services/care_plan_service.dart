import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/care_plan_model.dart';

class CarePlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new care plan
  Future<String?> createCarePlan(CarePlan carePlan) async {
    try {
      final docRef = await _firestore.collection('care_plans').add(carePlan.toMap());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating care plan: $e');
      return null;
    }
  }

  /// Get care plans for a specific client
  Stream<List<CarePlan>> getClientCarePlans(String clientId) {
    return _firestore
        .collection('care_plans')
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CarePlan.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get a single care plan by ID
  Future<CarePlan?> getCarePlan(String carePlanId) async {
    try {
      final doc = await _firestore.collection('care_plans').doc(carePlanId).get();
      if (doc.exists) {
        return CarePlan.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting care plan: $e');
      return null;
    }
  }

  /// Update a care plan
  Future<bool> updateCarePlan(String carePlanId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('care_plans').doc(carePlanId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating care plan: $e');
      return false;
    }
  }

  /// Deactivate a care plan (soft delete)
  Future<bool> deactivateCarePlan(String carePlanId) async {
    try {
      await _firestore.collection('care_plans').doc(carePlanId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deactivating care plan: $e');
      return false;
    }
  }

  /// Delete a care plan permanently
  Future<bool> deleteCarePlan(String carePlanId) async {
    try {
      await _firestore.collection('care_plans').doc(carePlanId).delete();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting care plan: $e');
      return false;
    }
  }

  /// Get all active care plans (admin)
  Stream<List<CarePlan>> getAllActiveCarePlans() {
    return _firestore
        .collection('care_plans')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CarePlan.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get care plans by care type
  Stream<List<CarePlan>> getCarePlansByCareType(String clientId, CareType careType) {
    return _firestore
        .collection('care_plans')
        .where('clientId', isEqualTo: clientId)
        .where('careType', isEqualTo: careType.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CarePlan.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
