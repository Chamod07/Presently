import 'package:flutter_app/services/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageService {
  final client = Supabase.instance.client;
  final supabaseService = SupabaseService();

  Future<Map<String, dynamic>?> getHomePageData() async {
    try {
      // Get current user ID
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      // Get user details from database
      final response = await client
          .from('UserDetails')
          .select('firstName, role')
          .eq('userId', userId)
          .single();

      if (response == null) return null;

      // Get avatar URL using the centralized method
      final avatarUrl = supabaseService.getAvatarUrl(userId: userId) ?? '';

      return {
        'first_name': response['firstName'] ?? '',
        'role': response['role'] ?? '',
        'avatar_url': avatarUrl,
      };
    } catch (e) {
      print('Error in getHomePageData: $e');
      return null;
    }
  }
}
