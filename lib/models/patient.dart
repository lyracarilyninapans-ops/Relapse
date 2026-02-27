import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String caregiverUid;
  final String name;
  final int? age;
  final String? notes;
  final String? photoUrl;
  final String? pairedWatchId;
  final DateTime createdAt;

  const Patient({
    required this.id,
    required this.caregiverUid,
    required this.name,
    this.age,
    this.notes,
    this.photoUrl,
    this.pairedWatchId,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      caregiverUid: json['caregiverUid'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      pairedWatchId: json['pairedWatchId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverUid': caregiverUid,
      'name': name,
      'age': age,
      'notes': notes,
      'photoUrl': photoUrl,
      'pairedWatchId': pairedWatchId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Patient copyWith({
    String? id,
    String? caregiverUid,
    String? name,
    int? age,
    String? notes,
    String? photoUrl,
    String? pairedWatchId,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      caregiverUid: caregiverUid ?? this.caregiverUid,
      name: name ?? this.name,
      age: age ?? this.age,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      pairedWatchId: pairedWatchId ?? this.pairedWatchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
