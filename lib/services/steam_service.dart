import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/steam_user.dart';
import '../models/steam_game.dart';
import '../models/steam_achievement.dart';

class SteamService {
  final Dio _dio = Dio();

  Future<SteamUser?> login(String steamId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/auth/login';
      final response = await _dio.post(url, data: {'steamId': steamId});
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        return SteamUser.fromJson(data);
      }
    } catch (e) {
      print('Error logging in: $e');
    }
    return null;
  }

  Future<SteamUser?> getUserSummary(String steamId) async {
    try {
      final url = '${AppConstants.baseUrl}/api/steam/user/$steamId';
      print('SteamService: Fetching user summary from $url (OS: ${Platform.operatingSystem})');
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        // Backend now returns the single User object directly
        return SteamUser.fromJson(data);
      }
    } catch (e) {
      print('Error fetching user summary: $e');
    }
    return null;
  }

  Future<List<SteamGame>> getOwnedGames(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/games/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        final games = data as List?;
        if (games != null) {
          return games.map((g) => SteamGame.fromJson(g)).toList();
        }
      }
    } catch (e) {
      print('Error fetching owned games: $e');
    }
    return [];
  }

  Future<List<SteamAchievement>> getPlayerAchievements(String steamId, int appId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/achievements/$steamId/$appId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        final achievementsData = data as List?;
        if (achievementsData == null) return [];

        return achievementsData.map((a) => SteamAchievement.fromJson(a)).toList();
      }
    } catch (e) {
      print('Error fetching achievements: $e');
    }
    return [];
  }

  Future<List<SteamUser>> getFriendList(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/friends/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        final players = data as List?;
        if (players != null) {
          return players.map((p) => SteamUser.fromJson(p)).toList();
        }
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
    return [];
  }

  Future<List<SteamGame>> getRecentlyPlayedGames(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/recently-played/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        final games = data as List?;
        if (games != null) {
          return games.map((g) => SteamGame.fromJson(g)).toList();
        }
      }
    } catch (e) {
      print('Error fetching recently played: $e');
    }
    return [];
  }

  Future<int> getSteamLevel(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/level/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        return data as int;
      }
    } catch (e) {
      print('Error fetching level: $e');
    }
    return 0;
  }

  Future<Map<String, dynamic>> getPlayerBans(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/bans/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('Error fetching bans: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>> getBadges(String steamId) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/api/steam/badges/$steamId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('Error fetching badges: $e');
    }
    return {};
  }
}
