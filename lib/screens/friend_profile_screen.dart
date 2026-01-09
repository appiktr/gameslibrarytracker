import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/steam_user.dart';
import '../models/steam_game.dart';
import '../providers/steam_provider.dart';

class FriendProfileScreen extends StatefulWidget {
  final SteamUser friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late Future<List<SteamGame>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch games for this friend
    _gamesFuture = Provider.of<SteamProvider>(context, listen: false).steamService.getOwnedGames(widget.friend.steamId);
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
                        return Card(
                          color: const Color(0xFF2A475E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
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
                            title: Text(
                              game.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${(game.playtimeForever / 60).toStringAsFixed(1)} h',
                              style: const TextStyle(color: Colors.white70),
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
}
