import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/steam_user.dart';
import '../models/steam_game.dart';
import '../models/local_game_data.dart';
import '../services/steam_service.dart';
import '../services/local_data_service.dart';

class SteamProvider with ChangeNotifier {
  final SteamService _steamService = SteamService();
  final LocalDataService _localDataService = LocalDataService();

  SteamUser? _user;
  List<SteamGame> _games = [];
  bool _isLoading = false;
  bool _isDemo = false;

  List<SteamUser> _friends = [];
  List<SteamGame> _recentGames = [];
  int _level = 0;
  Map<String, dynamic> _bans = {};
  Map<String, dynamic> _badges = {};
  Map<int, LocalGameData> _localGameData = {};

  SteamUser? get user => _user;
  List<SteamGame> get games => _games;
  List<SteamUser> get friends => _friends;
  List<SteamGame> get recentGames => _recentGames;
  int get level => _level;
  Map<String, dynamic> get bans => _bans;
  Map<String, dynamic> get badges => _badges;
  bool get isLoading => _isLoading;
  bool get isDemo => _isDemo;
  SteamService get steamService => _steamService;
  Map<int, LocalGameData> get localGameData => _localGameData;

  Future<void> login(String steamId) async {
    _isLoading = true;
    _isDemo = false;
    notifyListeners();

    try {
      // Use login endpoint to ensure user is saved to DB
      _user = await _steamService.login(steamId);
      if (_user != null) {
        // Save steamId for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('steamId', steamId);

        final results = await Future.wait([
          _steamService.getOwnedGames(steamId),
          _steamService.getFriendList(steamId),
          _steamService.getRecentlyPlayedGames(steamId),
          _steamService.getSteamLevel(steamId),
          _steamService.getPlayerBans(steamId),
          _steamService.getBadges(steamId),
          _localDataService.getAllLocalData(steamId),
        ]);

        _games = results[0] as List<SteamGame>;
        _friends = results[1] as List<SteamUser>;
        _recentGames = results[2] as List<SteamGame>;
        _level = results[3] as int;
        _bans = results[4] as Map<String, dynamic>;
        _badges = results[5] as Map<String, dynamic>;
        _localGameData = results[6] as Map<int, LocalGameData>;

        // Sort games by playtime (descending)
        _games.sort((a, b) => b.playtimeForever.compareTo(a.playtimeForever));
      }
    } catch (e) {
      print('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final steamId = prefs.getString('steamId');
    if (steamId != null) {
      await login(steamId);
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('steamId');

    _user = null;
    _games = [];
    _friends = [];
    _recentGames = [];
    _level = 0;
    _bans = {};
    _badges = {};
    _localGameData = {};
    _isDemo = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_user == null) return;

    if (_isDemo) {
      loadMockData(); // Re-load mock data for effect
    } else {
      await login(_user!.steamId);
    }
  }

  Future<void> updateLocalGameData(LocalGameData data) async {
    if (_user == null) return;
    await _localDataService.saveGameData(_user!.steamId, data);
    _localGameData[data.appId] = data;
    notifyListeners();
  }

  void loadMockData() {
    _isLoading = true;
    _isDemo = true;
    notifyListeners();

    // Delayed simulation
    Future.delayed(const Duration(seconds: 1), () {
      _user = SteamUser(
        steamId: '76561198000000000',
        personName: 'Demo Gamer',
        profileUrl: 'https://steamcommunity.com',
        avatar: 'https://avatars.akamai.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb.jpg',
        avatarMedium: 'https://avatars.akamai.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_medium.jpg',
        avatarFull: 'https://avatars.akamai.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg',
        lastLogoff: 1672531200,
        personState: 1, // Online
      );

      _games = [
        SteamGame(
          appId: 730,
          name: 'Counter-Strike 2',
          playtimeForever: 12000,
          imgIconUrl: '381315d038dc7981504938645a2082e05c3b9b46',
        ),
        SteamGame(
          appId: 570,
          name: 'Dota 2',
          playtimeForever: 8500,
          imgIconUrl: '0bbb630d63262dd66d2fdd0f7d37e8661a410075',
        ),
        SteamGame(
          appId: 440,
          name: 'Team Fortress 2',
          playtimeForever: 5000,
          imgIconUrl: 'e3f595a92552a336eec7995a9478f7762696f8b1',
        ),
        SteamGame(
          appId: 271590,
          name: 'Grand Theft Auto V',
          playtimeForever: 4500,
          imgIconUrl: '1e72f87245c361413158097d745a557342898c6d',
        ),
        SteamGame(
          appId: 1091500,
          name: 'Cyberpunk 2077',
          playtimeForever: 3200,
          imgIconUrl: '037905c1926618585474320422df5952f4af79cc',
        ),
        SteamGame(
          appId: 1172470,
          name: 'Apex Legends',
          playtimeForever: 2800,
          imgIconUrl: '407e3713f86e342777170138545e82f7c0406087',
        ),
        SteamGame(
          appId: 252490,
          name: 'Rust',
          playtimeForever: 2100,
          imgIconUrl: '895ce49a215320e69ffab42fb48e64c11b11b518',
        ),
        SteamGame(
          appId: 230410,
          name: 'Warframe',
          playtimeForever: 1800,
          imgIconUrl: '89d5f7560d2cf37748881aa554ae959f64e62846',
        ),
      ];

      _recentGames = _games.take(3).toList();
      _friends = [
        SteamUser(
          steamId: '1',
          personName: 'GabeN',
          profileUrl: '',
          avatar: '',
          avatarMedium: '',
          avatarFull: 'https://avatars.akamai.steamstatic.com/c5d56288414441eea972c647b1e428811d332619_full.jpg',
          lastLogoff: 0,
          personState: 1,
        ),
        SteamUser(
          steamId: '2',
          personName: 'Pro Player',
          profileUrl: '',
          avatar: '',
          avatarMedium: '',
          avatarFull: 'https://avatars.akamai.steamstatic.com/0237e1a90c50d877292215c2ba5427d14300a293_full.jpg',
          lastLogoff: 0,
          personState: 0,
        ),
        SteamUser(
          steamId: '3',
          personName: 'Steam Friend',
          profileUrl: '',
          avatar: '',
          avatarMedium: '',
          avatarFull: 'https://avatars.akamai.steamstatic.com/1360156d11e5cd97034c568ac8635c02280d859d_full.jpg',
          lastLogoff: 0,
          personState: 1,
        ),
      ];

      _level = 42;
      _bans = {'VACBanned': false, 'NumberOfGameBans': 0};
      _badges = {'player_xp': 15000};

      // Sort games
      _games.sort((a, b) => b.playtimeForever.compareTo(a.playtimeForever));

      _isLoading = false;
      notifyListeners();
    });
  }
}
