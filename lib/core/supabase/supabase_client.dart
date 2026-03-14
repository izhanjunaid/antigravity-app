import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a centralized accessor for the Supabase client.
/// The UI must never call Supabase directly — use services instead.
class SupabaseClientHelper {
  SupabaseClientHelper._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
