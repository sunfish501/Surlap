import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';

Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) { return; }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

SupabaseClient? get sb {
  if (supabaseUrl.isEmpty) { return null; }
  try { return Supabase.instance.client; } catch (_) { return null; }
}
