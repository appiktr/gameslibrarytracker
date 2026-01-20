import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/steam_user.dart';
import '../models/steam_game.dart';
import '../models/local_game_data.dart';
import '../providers/steam_provider.dart';
import '../services/local_data_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final SteamUser friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late Future<List<SteamGame>> _gamesFuture;
  final LocalDataService _localDataService = LocalDataService();
  Map<int, LocalGameData> _friendGameData = {};

  @override
  void initState() {
    super.initState();
    // Fetch games for this friend
    _gamesFuture = Provider.of<SteamProvider>(context, listen: false).steamService.getOwnedGames(widget.friend.steamId);
    // Fetch friend's reviews/notes
    _loadFriendGameData();
  }

  Future<void> _loadFriendGameData() async {
    final data = await _localDataService.getAllLocalData(widget.friend.steamId);
    if (mounted) {
      setState(() {
        _friendGameData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(widget.friend.personName)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171A21), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              CircleAvatar(radius: 50, backgroundImage: CachedNetworkImageProvider(widget.friend.avatarFull)),
              const SizedBox(height: 16),
              Text(
                widget.friend.personName,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.friend.personState == 1 ? 'Online' : 'Offline',
                style: TextStyle(
                  color: widget.friend.personState == 1 ? Colors.greenAccent : Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              // Games List
              Expanded(
                child: FutureBuilder<List<SteamGame>>(
                  future: _gamesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No games found or profile/games are private.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    final games = snapshot.data!;
                    // Sort by playtime
                    games.sort((a, b) => b.playtimeForever.compareTo(a.playtimeForever));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final gameData = _friendGameData[game.appId];
                        final hasReview = gameData != null && 
                            (gameData.rating != null || 
                             (gameData.notes != null && gameData.notes!.isNotEmpty) ||
                             gameData.status != LocalGameStatus.none);

                        return Card(
                          color: const Color(0xFF2A475E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: game.imgIconUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: game.iconUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) =>
                                                  const Icon(Icons.videogame_asset, color: Colors.white54),
                                            )
                                          : const Icon(Icons.videogame_asset, size: 50, color: Colors.white54),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game.name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(game.playtimeForever / 60).toStringAsFixed(1)} saat',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (gameData?.rating != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${gameData!.rating!.toInt()}/10',
                                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                // Show review if exists
                                if (hasReview) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B2838),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF66C0F4).withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (gameData.status != LocalGameStatus.none)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(bottom: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(gameData.status).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getStatusText(gameData.status),
                                              style: TextStyle(
                                                color: _getStatusColor(gameData.status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (gameData.notes != null && gameData.notes!.isNotEmpty)
                                          Text(
                                            gameData.notes!,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(LocalGameStatus status) {
    switch (status) {
      case LocalGameStatus.playing:
        return Colors.greenAccent;
      case LocalGameStatus.completed:
        return Colors.blueAccent;
      case LocalGameStatus.backlog:
        return Colors.orangeAccent;
      case LocalGameStatus.dropped:
        return Colors.redAccent;
      case LocalGameStatus.none:
        return Colors.grey;
    }
  }

  String _getStatusText(LocalGameStatus status) {
    switch (status) {
      case LocalGameStatus.playing:
        return 'OYNUYOR';
      case LocalGameStatus.completed:
        return 'BİTİRDİ';
      case LocalGameStatus.backlog:
        return 'SIRADA';
      case LocalGameStatus.dropped:
        return 'BIRAKTI';
      case LocalGameStatus.none:
        return '';
    }
  }
}
