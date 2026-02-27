class CaregiverProfile {
  final String uid;
  final String name;
  final String? phone;
  final String? bio;
  final String? photoUrl;

  const CaregiverProfile({
    required this.uid,
    required this.name,
    this.phone,
    this.bio,
    this.photoUrl,
  });

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) {
    return CaregiverProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'bio': bio,
      'photoUrl': photoUrl,
    };
  }

  CaregiverProfile copyWith({
    String? uid,
    String? name,
    String? phone,
    String? bio,
    String? photoUrl,
  }) {
    return CaregiverProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
