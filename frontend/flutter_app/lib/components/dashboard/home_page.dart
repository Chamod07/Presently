import 'package:flutter/material.dart';
import 'package:flutter_app/components/dashboard/navbar.dart';
import 'package:flutter_app/components/scenario_selection/session_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/services/home_page/home_page_service.dart';
import 'package:flutter_app/utils/image_utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final homePageService = HomePageService();
  String? firstName;
  String? avatarUrl;
  bool isLoading = true;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    Provider.of<SessionProvider>(context, listen: false)
        .loadSessionsFromSupabase();
    _loadHomePageData();
  }

  Future<void> _loadHomePageData() async {
    setState(() => isLoading = true);

    try {
      final homePageData = await homePageService.getHomePageData();
      if (homePageData != null && mounted) {
        setState(() {
          firstName = homePageData['first_name'];
          avatarUrl = homePageData['avatar_url'];
        });
      }
    } catch (e) {
      print('Error loading home page data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showRenameDialog(String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Session'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(fontFamily: 'Roboto', color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty &&
                    controller.text != currentName) {
                  Provider.of<SessionProvider>(context, listen: false)
                      .renameSession(currentName, controller.text);
                }
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF7400B8)),
              child: Text('Save',
                  style: TextStyle(fontFamily: 'Roboto', color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String sessionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Session'),
          content: Text('Are you sure you want to delete "$sessionName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false)
                    .deleteSession(sessionName);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Text(
              'Presently',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                fontFamily: 'Cookie',
                color: Color(0xFF7400B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to profile page
                Navigator.pushNamed(context, '/settings');
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF7400B8).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 26,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F0FF)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section with enhanced styling
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7400B8).withOpacity(0.8),
                      Color(0xFF6930C3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7400B8).withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello ${firstName ?? ''},',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 6.0),
                          Text(
                            'Let\'s ace your next presentation',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0),

              // Action buttons row with improved styling
              Row(
                children: [
                  // Start Session button with shadow and improved styling - fixed icon visibility
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/scenario_sel');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7400B8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Color(0xFF7400B8).withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Start Session',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Tasks button with improved styling
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/task_group_page');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 2,
                        shadowColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list, size: 18, color: Color(0xFF7400B8)),
                          SizedBox(width: 8),
                          Text('Tasks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7400B8),
                              )),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Filter button with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color: showFavoritesOnly
                          ? Color(0xFF7400B8).withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showFavoritesOnly
                            ? Color(0xFF7400B8)
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        showFavoritesOnly ? Icons.bookmark : Icons.filter_list,
                        color: showFavoritesOnly
                            ? Color(0xFF7400B8)
                            : Color(0xFF7400B8).withOpacity(0.7),
                        size: 22,
                      ),
                      tooltip: showFavoritesOnly
                          ? 'Show all sessions'
                          : 'Show bookmarked only',
                      onPressed: () {
                        setState(() {
                          showFavoritesOnly = !showFavoritesOnly;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.0),

              // Sessions heading with counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showFavoritesOnly
                          ? 'Bookmarked Sessions'
                          : 'Your Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Consumer<SessionProvider>(
                      builder: (context, provider, _) {
                        final sessionCount = showFavoritesOnly
                            ? provider
                                .getFilteredSessions(favoritesOnly: true)
                                .length
                            : provider.sessions.length;
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color(0xFF7400B8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$sessionCount ${sessionCount == 1 ? 'session' : 'sessions'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7400B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.0),

              // Sessions list with improved styling
              Expanded(
                child: Consumer<SessionProvider>(
                  builder: (context, sessionProvider, child) {
                    final filteredSessions =
                        sessionProvider.getFilteredSessions(
                      favoritesOnly: showFavoritesOnly,
                    );

                    // Sessions are now ordered by creation date from the provider

                    if (isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF7400B8)),
                        ),
                      );
                    }

                    if (filteredSessions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 16),
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        // Display creation date info in the card
                        return _buildCard(
                          session: session,
                          navigateTo: '/summary',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: ModalRoute.of(context)?.settings.arguments != null
            ? (ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>)['selectedIndex'] ??
                0
            : 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF7400B8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              showFavoritesOnly ? Icons.bookmark_border : Icons.mic_none,
              size: 60,
              color: Color(0xFF7400B8).withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            showFavoritesOnly
                ? 'No bookmarked sessions'
                : 'No sessions available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            showFavoritesOnly
                ? 'Bookmark sessions to find them quickly'
                : 'Start a new session to begin practicing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          SizedBox(height: 24),
          if (!showFavoritesOnly)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/scenario_sel');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400B8),
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Icon(Icons.add),
              label: Text('Start a Session'),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Map<String, dynamic> session,
    required String navigateTo,
  }) {
    final String sessionName = session['name'];
    final String sessionType = _formatSessionType(session['type']);
    final String audience = _formatAudience(session['audience']);
    final bool isFavorite = session['is_favorite'] ?? false;
    final String topic = session['topic'] ?? 'General Topic';

    // Format the creation date
    String createdAt = 'Recently created';
    if (session['created_at'] != null) {
      try {
        final DateTime dateTime = DateTime.parse(session['created_at']);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(dateTime);

        if (difference.inDays > 0) {
          createdAt =
              '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
        } else if (difference.inHours > 0) {
          createdAt =
              '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
        } else if (difference.inMinutes > 0) {
          createdAt =
              '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
        } else {
          createdAt = 'Just now';
        }
      } catch (e) {
        // Fallback if date parsing fails
        createdAt = 'Recently created';
      }
    }

    // Generate a consistent pastel color from the session name
    final int hashCode = sessionName.hashCode;
    final List<Color> pastels = [
      Color(0xFFE6F7FF), // Light Blue
      Color(0xFFE6FFFA), // Light Teal
      Color(0xFFF0F5FF), // Light Indigo
      Color(0xFFF9F0FF), // Light Purple
      Color(0xFFFFF0F6), // Light Pink
    ];
    final Color accentColor = pastels[hashCode.abs() % pastels.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, navigateTo);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top section with header accent color
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    // Type icon in circle
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(session['type']),
                        size: 18,
                        color: Color(0xFF7400B8),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Type and audience text
                    Expanded(
                      child: Text(
                        '$sessionType • $audience',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Bookmark button
                    Material(
                      color: Colors.transparent,
                      shape: CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          Provider.of<SessionProvider>(context, listen: false)
                              .toggleFavorite(sessionName);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            isFavorite ? Icons.bookmark : Icons.bookmark_border,
                            color: isFavorite ? Colors.deepPurple : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session name and created date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sessionName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          createdAt,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Topic with icon
                    Row(
                      children: [
                        Icon(
                          Icons.subject,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Bottom action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Practice button
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, navigateTo);
                          },
                          icon: Icon(Icons.play_arrow, size: 18),
                          label: Text('Continue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF7400B8),
                            side: BorderSide(color: Color(0xFF7400B8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // More options button
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[700],
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation(sessionName);
                            } else if (value == 'rename') {
                              _showRenameDialog(sessionName);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      size: 18, color: Colors.blue[800]),
                                  SizedBox(width: 12),
                                  Text('Rename',
                                      style: TextStyle(fontFamily: 'Roboto')),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(fontFamily: 'Roboto')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get icon for presentation type
  IconData _getIconForType(String? type) {
    if (type == null) return Icons.present_to_all;

    switch (type) {
      case 'business':
        return Icons.business;
      case 'academic':
        return Icons.school;
      case 'pub_speaking':
        return Icons.record_voice_over;
      case 'interview':
        return Icons.people;
      case 'casual':
        return Icons.chat;
      default:
        return Icons.present_to_all;
    }
  }

  // Format session type to be more readable
  String _formatSessionType(String? type) {
    if (type == null) return 'Presentation';

    switch (type) {
      case 'business':
        return 'Business';
      case 'academic':
        return 'Academic';
      case 'pub_speaking':
        return 'Public Speaking';
      case 'interview':
        return 'Interview';
      case 'casual':
        return 'Casual';
      default:
        return type.replaceFirst(type[0], type[0].toUpperCase());
    }
  }

  // Format audience to be more readable
  String _formatAudience(String? audience) {
    if (audience == null) return 'General';

    switch (audience) {
      case 'professionals':
        return 'Professionals';
      case 'students':
        return 'Students';
      case 'general_public':
        return 'General Public';
      case 'experts':
        return 'Experts';
      case 'mixed':
        return 'Mixed Audience';
      default:
        return audience.replaceFirst(audience[0], audience[0].toUpperCase());
    }
  }
}
