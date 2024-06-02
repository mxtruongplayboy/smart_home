class OpenDoorHistory {
  final String userId;
  final DateTime openAt;
  final String errorType;
  final String imageUrl;

  OpenDoorHistory({
    required this.userId,
    required this.openAt,
    required this.errorType,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'openAt': openAt.toIso8601String(),
      'errorType': errorType,
      'imageUrl': imageUrl,
    };
  }
}
