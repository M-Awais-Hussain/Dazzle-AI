import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseSecretKey => dotenv.env['SUPABASE_SECRET_KEY'] ?? '';
  static String get removeBgApiKey => dotenv.env['REMOVE_BG_API_KEY'] ?? '';
}
