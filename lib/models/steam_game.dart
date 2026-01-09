class SteamGame {
  final int appId;
  final String name;
  final int playtimeForever;
  final String imgIconUrl;

  SteamGame({required this.appId, required this.name, required this.playtimeForever, required this.imgIconUrl});

  factory SteamGame.fromJson(Map<String, dynamic> json) {
    return SteamGame(
      appId: json['appid'] ?? 0,
      name: json['name'] ?? 'Unknown Game',
      playtimeForever: json['playtime_forever'] ?? 0,
      imgIconUrl: json['img_icon_url'] ?? '',
    );
  }

  String get iconUrl {
    if (imgIconUrl.isEmpty) return '';
    if (imgIconUrl.startsWith('http')) return imgIconUrl;
    return 'http://media.steampowered.com/steamcommunity/public/images/apps/$appId/$imgIconUrl.jpg';
  }

  // Header image is usually better for lists
  String get headerImageUrl => 'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg';
}
