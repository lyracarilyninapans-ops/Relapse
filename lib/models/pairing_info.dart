import 'package:cloud_firestore/cloud_firestore.dart';

enum PairingStatus { pending, paired, unpaired }

class PairingInfo {
  final String pairingCode;
  final String? watchId;
  final DateTime? pairedAt;
  final PairingStatus status;

  const PairingInfo({
    required this.pairingCode,
    this.watchId,
    this.pairedAt,
    this.status = PairingStatus.pending,
  });

  factory PairingInfo.fromJson(Map<String, dynamic> json) {
    return PairingInfo(
      pairingCode: json['pairingCode'] as String,
      watchId: json['watchId'] as String?,
      pairedAt: json['pairedAt'] != null
          ? (json['pairedAt'] as Timestamp).toDate()
          : null,
      status: PairingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PairingStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingCode': pairingCode,
      'watchId': watchId,
      'pairedAt': pairedAt != null ? Timestamp.fromDate(pairedAt!) : null,
      'status': status.name,
    };
  }
}
