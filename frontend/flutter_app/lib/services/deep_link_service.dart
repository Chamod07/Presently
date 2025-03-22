import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_app/services/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import for OtpType

class DeepLinkService {
  final SupabaseService _supabaseService;
  final GlobalKey<NavigatorState> navigatorKey;
  late final AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  bool _initialUriHandled = false;

  DeepLinkService(this._supabaseService, this.navigatorKey) {
    _appLinks = AppLinks();
  }

  Future<void> init() async {
    // Handle initial Uri if the app was launched with one
    if (!_initialUriHandled) {
      _initialUriHandled = true;
      try {
        final initialUri = await _appLinks.getInitialAppLink();
        if (initialUri != null) {
          _handleDeepLink(initialUri);
        }
      } catch (e) {
        // Handle exception if unable to get initial URI
        debugPrint('Error getting initial URI: $e');
      }
    }

    // Handle links that open the app from background or terminated state
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Deep link received: $uri');
    debugPrint('Deep link host: ${uri.host}, path: ${uri.path}');
    debugPrint('Deep link query parameters: ${uri.queryParameters}');

    // Handle auth links
    if (uri.host == 'auth') {
      // Check if the URI is specifically for password reset
      final isPasswordReset = uri.queryParameters.containsKey('type') &&
          uri.queryParameters['type'] == 'recovery';

      // Check for code parameter (OAuth or session code)
      final code = _getParamFromUri(uri, 'code');

      if (code != null && code.isNotEmpty) {
        debugPrint(
            'Authentication code found: ${code.substring(0, 5)}... isPasswordReset: $isPasswordReset');

        try {
          // Exchange the code for a session (will sign the user in)
          await _supabaseService.client.auth.exchangeCodeForSession(code);
          debugPrint('Successfully exchanged code for session');

          // For password reset, we need to check if this is an OAuth user
          if (isPasswordReset) {
            final currentUser = await _supabaseService.client.auth.currentUser;

            // Debug the user's identity providers
            if (currentUser != null) {
              final identities = currentUser.identities;
              debugPrint(
                  'User identities: ${identities?.map((i) => i.provider).toList()}');

              // Check if this is an OAuth user (only provider is not 'email')
              final isOAuthOnlyUser = identities != null &&
                  identities.length == 1 &&
                  identities[0].provider != 'email';

              if (isOAuthOnlyUser) {
                debugPrint('This is an OAuth-only user, cannot reset password');
                // Navigate to a special page or show dialog explaining they used Google to sign in
                if (navigatorKey.currentState != null) {
                  // Show dialog explaining they used OAuth instead
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: navigatorKey.currentState!.context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Password Reset Not Available'),
                          content: const Text(
                            'You signed up using Google, not with an email and password. '
                            'Please continue to use Google to sign in to your account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                navigatorKey.currentState!
                                    .pushReplacementNamed('/sign_in');
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                  return;
                }
              }
            }

            debugPrint(
                'This is a standard user, navigating to reset password page');
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!
                  .pushReplacementNamed('/reset_password');
            }
            return;
          }

          // For regular sign-in, go to home
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushReplacementNamed('/home');
          }
          return;
        } catch (e) {
          debugPrint('Error exchanging code for session: $e');
          // Continue to other handlers in case this is not an auth code
        }
      }

      // More flexible path checking for reset password
      if (uri.path.contains('reset-password') ||
          uri.path.contains('recovery') ||
          uri.path.contains('password') ||
          uri.queryParameters.containsKey('type') &&
              uri.queryParameters['type'] == 'recovery') {
        // Look for token in various parameter names
        String? token = _getParamFromUri(uri, 'token');
        if (token == null) token = _getParamFromUri(uri, 'access_token');
        if (token == null) token = _getParamFromUri(uri, 't');

        debugPrint(
            'Token extracted: ${token != null ? 'Found (${token.length} chars)' : 'Not found'}');

        if (token != null && token.isNotEmpty) {
          // Set the auth session for this token
          try {
            // First try to set the auth session with the token
            await _supabaseService.client.auth.setSession(token);
            debugPrint('Auth session set successfully with token');
          } catch (e) {
            debugPrint('Error setting auth session: $e');
            // Continue anyway as we'll pass the token to the reset page
          }

          // Navigate to reset password page with token
          if (navigatorKey.currentState != null) {
            debugPrint('Navigating to reset_password page');
            navigatorKey.currentState!.pushNamed(
              '/reset_password',
              arguments: {'token': token},
            );
          } else {
            debugPrint('Navigator state is null, cannot navigate');
          }
        } else {
          debugPrint('No token found in the URI');
        }
      } else if (uri.path.contains('verify')) {
        // Handle email verification
        final token = _getParamFromUri(uri, 'token');
        if (token != null && token.isNotEmpty) {
          try {
            // Verify the user's email with Supabase
            await _supabaseService.client.auth.verifyOTP(
              token: token,
              type: OtpType.email,
            );
            // Navigate to home or show confirmation
            navigatorKey.currentState?.pushReplacementNamed('/home');
          } catch (e) {
            debugPrint('Error verifying email: $e');
            // Show error dialog
          }
        }
      }
    }
  }

  String? _getParamFromUri(Uri uri, String paramName) {
    return uri.queryParameters[paramName];
  }
}
