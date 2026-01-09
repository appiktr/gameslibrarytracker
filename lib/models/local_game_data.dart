import 'dart:convert';

enum LocalGameStatus { none, backlog, playing, completed, dropped }

class LocalGameData {
  final int appId;
  double? rating;
  String? notes;
  LocalGameStatus status;
  bool isFavorite;
  int? playOrder;

  LocalGameData({
    required this.appId,
    this.rating,
    this.notes,
    this.status = LocalGameStatus.none,
    this.isFavorite = false,
    this.playOrder,
  });

  // Serialization for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'rating': rating,
      'notes': notes,
      'status': status.index,
      'isFavorite': isFavorite,
      'playOrder': playOrder,
    };
  }

  factory LocalGameData.fromJson(Map<String, dynamic> json) {
    return LocalGameData(
      appId: json['appId'],
      rating: json['rating']?.toDouble(),
      notes: json['notes'],
      status: LocalGameStatus.values[json['status'] ?? 0],
      isFavorite: json['isFavorite'] ?? false,
      playOrder: json['playOrder'],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory LocalGameData.fromJsonString(String jsonString) {
    return LocalGameData.fromJson(jsonDecode(jsonString));
  }
}
