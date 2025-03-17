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
      final userDetailResponse = await _supabaseService.client
          .from('UserDetails')
          .select('firstName, lastName, role')
          .eq('userId', userId)
          .single();

      return {
        'first_name': userDetailResponse['firstName'] ?? 'User',
        // Remove avatar_url from returned data
      };
    } catch (e) {
      print('Error getting home page data: $e');
      return {
        'first_name': 'User',
      };
    }
  }
}
