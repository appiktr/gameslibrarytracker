import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/steam_game.dart';
import '../models/steam_achievement.dart';
import '../models/local_game_data.dart';
import '../services/steam_service.dart';
import '../providers/steam_provider.dart';

class GameDetailScreen extends StatefulWidget {
  final SteamGame game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final SteamService _service = SteamService();
  List<SteamAchievement> _achievements = [];
  bool _isLoading = true;

  late LocalGameData _localData;
  final TextEditingController _notesController = TextEditingController();
  bool _isEditing = false; // State to track edit mode

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _loadAchievements();
  }

  void _loadLocalData() {
    final provider = Provider.of<SteamProvider>(context, listen: false);
    final existingData = provider.localGameData[widget.game.appId];

    if (existingData != null) {
      _localData = existingData;
      // If we have data, we start in View mode
      _isEditing = false;
    } else {
      _localData = LocalGameData(appId: widget.game.appId);
      // No data yet, start in Edit mode (or View mode with empty state? Edit is better prompt)
      // Actually let's start in View mode but show "Add Review" button
      _isEditing = false;
    }
    _notesController.text = _localData.notes ?? '';
  }

  Future<void> _loadAchievements() async {
    final user = Provider.of<SteamProvider>(context, listen: false).user;
    if (user != null) {
      final list = await _service.getPlayerAchievements(user.steamId, widget.game.appId);
      if (mounted) {
        setState(() {
          _achievements = list;
          _isLoading = false;
        });
      }
    }
  }

  void _saveLocalData() {
    final provider = Provider.of<SteamProvider>(context, listen: false);
    _localData.notes = _notesController.text;
    provider.updateLocalGameData(_localData);

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved changes'), duration: Duration(seconds: 1)));
  }

  bool _hasLocalData() {
    return _localData.status != LocalGameStatus.none ||
        (_localData.notes != null && _localData.notes!.isNotEmpty) ||
        _localData.rating != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2838),
      appBar: AppBar(
        title: Text(widget.game.name),
        backgroundColor: const Color(0xFF171A21),
        actions: [
          IconButton(
            icon: Icon(
              _localData.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _localData.isFavorite ? Colors.redAccent : Colors.white,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              setState(() {
                _localData.isFavorite = !_localData.isFavorite;
              });
              // We auto-save favorite toggle because it acts like a switch
              final provider = Provider.of<SteamProvider>(context, listen: false);
              provider.updateLocalGameData(_localData);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _isEditing ? _buildLocalDataForm() : _buildLocalDataView(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _achievements.isEmpty
                ? _buildEmptyState()
                : _buildAchievementList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDataView() {
    if (!_hasLocalData()) {
      return Container(
        color: const Color(0xFF171A21),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit),
          label: const Text('Add Review / Notes'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A475E), foregroundColor: Colors.white),
        ),
      );
    }

    return Container(
      color: const Color(0xFF171A21),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Review',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit Review',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A475E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF66C0F4).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_localData.status != LocalGameStatus.none)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _localData.status.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_localData.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${_localData.rating}/10',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_localData.notes != null && _localData.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Text(_localData.notes!, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDataForm() {
    return Container(
      color: const Color(0xFF171A21),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Review',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => _isEditing = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<LocalGameStatus>(
                  value: _localData.status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    filled: true,
                    fillColor: Color(0xFF2A475E),
                  ),
                  dropdownColor: const Color(0xFF2A475E),
                  style: const TextStyle(color: Colors.white),
                  items: LocalGameStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _localData.status = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _localData.rating?.toInt(),
                  decoration: const InputDecoration(
                    labelText: 'Rating',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    filled: true,
                    fillColor: Color(0xFF2A475E),
                  ),
                  dropdownColor: const Color(0xFF2A475E),
                  style: const TextStyle(color: Colors.white),
                  items: List.generate(11, (index) {
                    return DropdownMenuItem<int>(value: index, child: Text(index.toString()));
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _localData.rating = val.toDouble());
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'My Notes',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              filled: true,
              fillColor: Color(0xFF2A475E),
              hintText: 'Add notes about this game...',
              hintStyle: TextStyle(color: Colors.white24),
            ),
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              onPressed: _saveLocalData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66C0F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'No achievements found or Profile Private',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Card(
          color: achievement.achieved ? const Color(0xFF2A475E) : const Color(0xFF171A21),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              achievement.achieved ? Icons.emoji_events : Icons.lock_outline,
              color: achievement.achieved ? Colors.amber : Colors.grey,
              size: 32,
            ),
            title: Text(
              achievement.name,
              style: TextStyle(
                color: achievement.achieved ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              achievement.description,
              style: TextStyle(color: achievement.achieved ? Colors.white70 : Colors.white24),
            ),
          ),
        );
      },
    );
  }
}
