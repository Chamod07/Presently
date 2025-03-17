import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageService {
  final client = Supabase.instance.client;

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

      // Check for avatar in multiple formats
      String avatarUrl = '';
      final extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

      for (final ext in extensions) {
        try {
          // Get public URL for potential avatar
          final url = client.storage
              .from('avatars')
              .getPublicUrl('avatar_$userId.$ext');

          // We'll add timestamp in the UI layer to ensure cache-busting
          avatarUrl = url;
          break;
        } catch (e) {
          // Continue trying other extensions
        }
      }

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
