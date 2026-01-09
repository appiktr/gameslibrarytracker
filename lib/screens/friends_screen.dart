import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/steam_provider.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = Provider.of<SteamProvider>(context).friends;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: friends.isEmpty
          ? const Center(
              child: Text('No friends found', style: TextStyle(color: Colors.white54)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  color: const Color(0xFF2A475E),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(friend.avatarMedium)),
                    title: Text(
                      friend.personName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      friend.personState == 1 ? 'Online' : 'Offline',
                      style: TextStyle(color: friend.personState == 1 ? Colors.greenAccent : Colors.grey),
                    ),
                    trailing: const Icon(Icons.visibility, color: Colors.white54),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FriendProfileScreen(friend: friend)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
