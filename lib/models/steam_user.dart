class SteamUser {
  final String steamId;
  final String personName;
  final String profileUrl;
  final String avatar;
  final String avatarMedium;
  final String avatarFull;
  final int lastLogoff;
  final int personState;

  SteamUser({
    required this.steamId,
    required this.personName,
    required this.profileUrl,
    required this.avatar,
    required this.avatarMedium,
    required this.avatarFull,
    required this.lastLogoff,
    required this.personState,
  });

  factory SteamUser.fromJson(Map<String, dynamic> json) {
    return SteamUser(
      steamId: json['steamid'] ?? '',
      personName: json['personaname'] ?? 'Unknown',
      profileUrl: json['profileurl'] ?? '',
      avatar: json['avatar'] ?? '',
      avatarMedium: json['avatarmedium'] ?? '',
      avatarFull: json['avatarfull'] ?? '',
      lastLogoff: json['lastlogoff'] ?? 0,
      personState: json['personastate'] ?? 0,
    );
  }
}
