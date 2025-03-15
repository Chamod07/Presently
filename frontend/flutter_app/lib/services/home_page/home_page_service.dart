import 'package:flutter_app/services/supabase/supabase_service.dart';

class HomePageService {
  final SupabaseService _supabaseService = SupabaseService();

  Future<Map<String, dynamic>?> getHomePageData() async {
    if (!_supabaseService.isSignedIn) return null;

    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        print('User ID is null');
        return null;
      }
      final profileResponse = await _supabaseService.client
          .from('UserDetails')
          .select('firstName')
          .eq('userId', userId)
          .single();

      final avatarResponse = await _supabaseService.client
          .from('Profile')
          .select('avatar_url')
          .eq('userId', userId)
          .maybeSingle();

      return {
        'first_name': profileResponse['firstName'] ?? 'User',
        'avatar_url': avatarResponse?['avatar_url'],
      };
    } catch (e) {
      print('Error getting home page data: $e');
      return {
        'first_name': 'User',
        'avatar_url': null,
      };
    }
  }
}
