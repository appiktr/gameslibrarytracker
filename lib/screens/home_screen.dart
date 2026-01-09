import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/steam_provider.dart';
import '../models/steam_user.dart';
import '../models/local_game_data.dart'; // Import LocalGameStatus

import 'game_detail_screen.dart';
import 'friends_screen.dart';

class HomeScreen extends StatefulWidget {
  // Converted to Stateful
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Filter state
  LocalGameStatus? _statusFilter;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SteamProvider>(context);
    final user = provider.user;
    var games = provider.games; // Mutable copy reference, we will filter below
    final recentGames = provider.recentGames;
    final bans = provider.bans;
    final badges = provider.badges;
    final localDataMap = provider.localGameData;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No User Data')));
    }

    // Apply Filters
    games = games.where((game) {
      final localData = localDataMap[game.appId];

      if (_showFavoritesOnly) {
        if (localData == null || !localData.isFavorite) return false;
      }

      if (_statusFilter != null) {
        if (localData == null || localData.status != _statusFilter) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Game Library Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Friends',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen()));
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh Data', onPressed: () => provider.refresh()),
          IconButton(
            icon: Icon(provider.isDemo ? Icons.login : Icons.logout),
            tooltip: provider.isDemo ? 'Login to Steam' : 'Logout',
            onPressed: () => provider.logout(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF171A21), // Steam Dark
              Color(0xFF1B2838), // Steam Blue-ish
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserProfile(user, provider.level, bans, badges),
                      if (recentGames.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Recently Played',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentGames.length,
                            itemBuilder: (context, index) {
                              final game = recentGames[index];
                              return GestureDetector(
                                // Simplified for brevity in this view
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
                                ),
                                child: Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: game.headerImageUrl,
                                          height: 100,
                                          width: 220,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        game.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Library',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          // Optional: Add sort button here if needed
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Favorites'),
                              selected: _showFavoritesOnly,
                              onSelected: (val) => setState(() => _showFavoritesOnly = val),
                              checkmarkColor: Colors.white,
                              selectedColor: Colors.redAccent,
                              backgroundColor: const Color(0xFF2A475E),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            ...LocalGameStatus.values.where((e) => e != LocalGameStatus.none).map((status) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(status.toString().split('.').last.toUpperCase()),
                                  selected: _statusFilter == status,
                                  onSelected: (val) => setState(() => _statusFilter = val ? status : null),
                                  checkmarkColor: Colors.white,
                                  selectedColor: Colors.blueAccent,
                                  backgroundColor: const Color(0xFF2A475E),
                                  labelStyle: const TextStyle(color: Colors.white),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (games.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No games match your filters or profile/games are private.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final game = games[index];
                      final localData = localDataMap[game.appId];
                      final isFavorite = localData?.isFavorite ?? false;
                      final status = localData?.status ?? LocalGameStatus.none;
                      final rating = localData?.rating;

                      return Card(
                        color: const Color(0xFF2A475E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
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
                              if (isFavorite)
                                const Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                                ),
                            ],
                          ),
                          title: Text(
                            game.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(game.playtimeForever / 60).toStringAsFixed(1)} hours',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              if (status != LocalGameStatus.none || rating != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      if (status != LocalGameStatus.none)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status.toString().split('.').last.toUpperCase(),
                                            style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                                          ),
                                        ),
                                      if (rating != null)
                                        Text('⭐ $rating', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              if (localData?.notes != null && localData!.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    localData.notes!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GameDetailScreen(game: game)),
                            );
                          },
                        ),
                      );
                    }, childCount: games.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(SteamUser user, int level, Map<String, dynamic> bans, Map<String, dynamic> badges) {
    bool isVacBanned = bans['VACBanned'] == true;
    int gameBans = bans['NumberOfGameBans'] ?? 0;
    int xp = badges['player_xp'] ?? 0;

    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: CircleAvatar(radius: 40, backgroundImage: CachedNetworkImageProvider(user.avatarFull)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: Text(
                  '$level',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.personName,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    user.personState == 1 ? 'Online' : 'Offline',
                    style: TextStyle(color: user.personState == 1 ? Colors.greenAccent : Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  Text('XP: $xp', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              if (isVacBanned || gameBans > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    isVacBanned ? 'VAC Banned' : '$gameBans Game Bans',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
