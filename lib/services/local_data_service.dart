import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/local_game_data.dart';

class LocalDataService {
  final Dio _dio = Dio();
  String get _baseUrl => '${AppConstants.baseUrl}/api/data';

  Future<void> init() async {
    // No initialization needed for HTTP
  }

  Future<void> saveGameData(String steamId, LocalGameData data) async {
    try {
      await _dio.post('$_baseUrl/$steamId/games/${data.appId}', data: data.toJson());
    } catch (e) {
      print('Error saving game data: $e');
    }
  }

  Future<LocalGameData?> getGameData(String steamId, int appId) async {
    try {
      final response = await _dio.get('$_baseUrl/$steamId/games/$appId');
      if (response.statusCode == 200 && response.data != null) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        return LocalGameData.fromJson(data);
      }
    } catch (e) {
      print('Error loading game data: $e');
    }
    return null;
  }

  Future<Map<int, LocalGameData>> getAllLocalData(String steamId) async {
    try {
      final response = await _dio.get('$_baseUrl/$steamId/games');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        if (data == null) return {};

        final mapData = data as Map<String, dynamic>;
        final Map<int, LocalGameData> result = {};
        mapData.forEach((key, value) {
          final appId = int.tryParse(key);
          if (appId != null) {
            result[appId] = LocalGameData.fromJson(value);
          }
        });
        return result;
      }
    } catch (e) {
      print('Error loading all local data: $e');
    }
    return {};
  }
}
