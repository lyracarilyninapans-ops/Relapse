import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/caregiver_profile.dart';

/// Firestore data source for user/caregiver profile data.
class UserRemoteSource {
  final FirebaseFirestore _firestore;

  UserRemoteSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Get caregiver profile.
  Future<CaregiverProfile?> getProfile(String uid) async {
    final doc = await _profileDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CaregiverProfile.fromJson({...doc.data()!, 'uid': uid});
  }

  /// Stream caregiver profile changes.
  Stream<CaregiverProfile?> watchProfile(String uid) {
    return _profileDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CaregiverProfile.fromJson({...doc.data()!, 'uid': uid});
    });
  }

  /// Update caregiver profile fields.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _profileDoc(uid).set(data, SetOptions(merge: true));
  }
}
