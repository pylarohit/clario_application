import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatefulWidget {
  final VoidCallback? onProfileClick;
  const ChatPage({super.key, this.onProfileClick});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  Stream<List<Map<String, dynamic>>>? _roomsStream;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _setupRoomsStream();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userMetadata = user.userMetadata;
        if (userMetadata != null) {
          final photoUrl = userMetadata['avatar_url'] ?? userMetadata['picture'];
          if (photoUrl != null) {
            setState(() => _userPhotoUrl = photoUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  void _setupRoomsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _roomsStream = _supabase
          .from('chat_rooms')
          .stream(primaryKey: ['id'])
          .order('updated_at')
          .map((maps) => maps.where((m) => m['student_id'] == userId || m['mentor_id'] == userId).toList());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB1A9DE), // Lavender Background
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          final rooms = snapshot.data ?? [];
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          
          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        _buildHeaderRow(),
                        const SizedBox(height: 30),
                        _buildActivitiesSection(rooms),
                        const SizedBox(height: 30),
                        _buildMessagesSection(rooms, isLoading),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Placeholder to balance
          GestureDetector(
            onTap: () => widget.onProfileClick?.call(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5E9EF5),
              backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
              onBackgroundImageError: _userPhotoUrl != null
                  ? (exception, stackTrace) {
                      setState(() {
                        _userPhotoUrl = null;
                      });
                    }
                  : null,
              child: _userPhotoUrl == null
                  ? Text(
                      _supabase.auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chat',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B2347),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFB1A9DE).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search, color: Color(0xFF6B4EE0), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(List<Map<String, dynamic>> rooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Activities',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B2347),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: rooms.map((room) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF6B4EE0), width: 2.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(room['mentor_avatar'] ?? 'https://i.pravatar.cc/150?u=chat'),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesSection(List<Map<String, dynamic>> rooms, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Messages',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B2347),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6B4EE0))),
          )
        else if (rooms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No messages yet',
                style: GoogleFonts.outfit(color: Colors.black38),
              ),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 100, right: 24),
              child: Divider(color: Colors.grey.withOpacity(0.1), thickness: 1),
            ),
            itemBuilder: (context, index) => _buildChatItem(rooms[index]),
          ),
      ],
    );
  }

  Widget _buildChatItem(Map<String, dynamic> room) {
    // Calculate relative time
    String timeAgo = 'Now';
    if (room['updated_at'] != null) {
      final updated = DateTime.parse(room['updated_at']);
      final diff = DateTime.now().difference(updated);
      if (diff.inMinutes < 1) {
        timeAgo = 'Now';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} hr';
      } else {
        timeAgo = '${diff.inDays} d';
      }
    }

    final int unreadCount = room['unread_count'] ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              roomId: room['id'],
              mentorName: room['mentor_name'] ?? 'Mentor',
              mentorPosition: room['mentor_position'] ?? 'Expert',
              mentorAvatar: room['mentor_avatar'] ?? 'https://i.pravatar.cc/150?u=chat',
              isOnline: room['is_online'] ?? false,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(room['mentor_avatar'] ?? 'https://i.pravatar.cc/150?u=chat'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['mentor_name'] ?? 'Unknown',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B4EE0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room['last_message'] ?? 'Start a conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B4EE0),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ... rest of file (ChatDetailPage)

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String mentorName;
  final String mentorPosition;
  final String mentorAvatar;
  final bool isOnline;

  const ChatDetailPage({super.key, required this.roomId, required this.mentorName, required this.mentorPosition, required this.mentorAvatar, required this.isOnline});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final photoUrl = user.userMetadata!['avatar_url'] ?? user.userMetadata!['picture'];
      if (photoUrl != null) {
        setState(() => _userPhotoUrl = photoUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('messages').stream(primaryKey: ['id']).eq('room_id', widget.roomId).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EE0)));
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _supabase.auth.currentUser?.id;
                    return _buildModernBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputPill(),
        ],
      ),
    );
  }



  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF6B4EE0),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.only(top: 50, bottom: 24, left: 16, right: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(widget.mentorAvatar),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.mentorName,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Online',
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernBubble(Map<String, dynamic> msg, bool isMe) {
    final String time = msg['created_at'] != null ? DateFormat.jm().format(DateTime.parse(msg['created_at'])) : '';
    final String text = msg['text'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.mentorAvatar)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF6B4EE0) : const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.outfit(color: isMe ? Colors.white : const Color(0xFF1B2347), fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isMe)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF5E9EF5),
                  backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
                  onBackgroundImageError: _userPhotoUrl != null
                      ? (exception, stackTrace) {
                          setState(() {
                            _userPhotoUrl = null;
                          });
                        }
                      : null,
                  child: _userPhotoUrl == null
                      ? Text(
                          _supabase.auth.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        )
                      : null,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 50, right: isMe ? 50 : 0),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (isMe) const Icon(Icons.done_all, size: 14, color: Color(0xFF6B4EE0)),
                const SizedBox(width: 4),
                Text(time, style: GoogleFonts.outfit(color: Colors.black38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: Colors.white,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.name != null) {
                  final fileName = result.files.single.name;
                  final now = DateTime.now().toIso8601String();
                  
                  // 1. Insert message
                  await _supabase.from('messages').insert({
                    'room_id': widget.roomId,
                    'sender_id': _supabase.auth.currentUser?.id,
                    'text': 'Attachment: $fileName',
                    'created_at': now,
                  });

                  // 2. Update room summary
                  await _supabase.from('chat_rooms').update({
                    'last_message': 'Attachment: $fileName',
                    'updated_at': now,
                  }).eq('id', widget.roomId);
                }
              },
              child: const Icon(Icons.attach_file, color: Colors.black26, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter Message',
                  hintStyle: GoogleFonts.outfit(color: Colors.black26),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                final txt = _messageController.text.trim();
                if (txt.isEmpty) return;
                _messageController.clear();
                
                final now = DateTime.now().toIso8601String();
                
                // 1. Insert message
                await _supabase.from('messages').insert({
                  'room_id': widget.roomId,
                  'sender_id': _supabase.auth.currentUser?.id,
                  'text': txt,
                  'created_at': now,
                });

                // 2. Update room summary
                await _supabase.from('chat_rooms').update({
                  'last_message': txt,
                  'updated_at': now,
                }).eq('id', widget.roomId);
              },
              child: const Icon(Icons.send_rounded, color: Color(0xFF6B4EE0)),
            ),
          ],
        ),
      ),
    );
  }
}
