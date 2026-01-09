class SteamAchievement {
  final String apiName;
  final bool achieved;
  final int unlockTime;
  final String name;
  final String description;

  SteamAchievement({
    required this.apiName,
    required this.achieved,
    required this.unlockTime,
    required this.name,
    required this.description,
  });

  factory SteamAchievement.fromJson(Map<String, dynamic> json) {
    return SteamAchievement(
      apiName: json['apiname'] ?? '',
      achieved: json['achieved'] == true,
      unlockTime: json['unlocktime'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
