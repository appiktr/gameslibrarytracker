import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get steamApiKey => dotenv.env['STEAM_API_KEY'] ?? '';
  static String get baseUrl => 'http://igsgk04sow0g4wwccwc40g4g.46.224.57.253.sslip.io';
}
