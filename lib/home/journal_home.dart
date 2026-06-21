import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/horizontal_calendar.dart';

class JournalHomePage extends StatefulWidget {
  final VoidCallback? onProfileClick;
  const JournalHomePage({super.key, this.onProfileClick});

  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage> {
  DateTime _selectedDateValue = DateTime.now();

  // Initialize with an empty list to show only user-added tasks
  List<Map<String, dynamic>> _userTasks = [];
  bool _isLoadingTasks = false;
  String _userName = 'User';
  String? _userPhotoUrl;

  DateTime get _selectedDate => _selectedDateValue;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchTasks();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userMetadata = user.userMetadata;
        if (userMetadata != null) {
          final photoUrl = userMetadata['avatar_url'] ?? userMetadata['picture'];
          final name = userMetadata['full_name'] ?? user.email?.split('@')[0] ?? 'User';
          setState(() {
            _userName = name;
            _userPhotoUrl = photoUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('journal_tasks')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (response != null) {
          setState(() {
            _userTasks = List<Map<String, dynamic>>.from(response).map((task) {
              Color taskColor = const Color(0xFFFFB74D);
              if (task['color'] != null) {
                try {
                  String colorVal = task['color'].replaceFirst('#', '');
                  taskColor = Color(int.parse("FF$colorVal", radix: 16));
                } catch (e) {
                  debugPrint('Color parse error: $e');
                }
              }
              
              return {
                ...task,
                'color': taskColor,
                'date': DateTime.parse(task['task_date']),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _addTaskToDatabase({
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
    required DateTime date,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final hexColor = color.value.toRadixString(16).substring(2).toUpperCase();

      await Supabase.instance.client.from('journal_tasks').insert({
        'user_id': user.id,
        'title': title,
        'subtitle': subtitle,
        'tag': tag,
        'color': '#$hexColor',
        'task_date': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _fetchTasks();
    } catch (e) {
      debugPrint('Error adding task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedTag = 'Personal';
    DateTime dialogSelectedDate = _selectedDate;
    final List<String> tags = ['Personal', 'Family', 'Work', 'Health', 'Focus'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add New Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Task Title',
                  hintStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(
                  hintText: 'Short description',
                  hintStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                     child: DropdownButtonHideUnderline(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12),
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.black12),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: DropdownButton<String>(
                            value: selectedTag,
                            items: tags.map((String tag) {
                              return DropdownMenuItem<String>(
                                value: tag,
                                child: Text(tag, style: GoogleFonts.outfit(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setDialogState(() => selectedTag = value);
                            },
                          ),
                       ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dialogSelectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() => dialogSelectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                      const SizedBox(width: 10),
                      Text(
                        "${dialogSelectedDate.day}/${dialogSelectedDate.month}/${dialogSelectedDate.year}",
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _addTaskToDatabase(
                    title: titleController.text,
                    subtitle: subtitleController.text,
                    tag: selectedTag,
                    color: _getTagColor(selectedTag),
                    date: dialogSelectedDate,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Personal': return const Color(0xFFF8D7DA);
      case 'Family': return const Color(0xFFE2E3FF);
      case 'Work': return const Color(0xFFD4EDDA);
      case 'Health': return const Color(0xFFFFF3CD);
      case 'Focus': return const Color(0xFFE0F7FA);
      default: return Colors.white;
    }
  }

  final List<Map<String, String>> _calendarDays = [
    {'day': 'Mon', 'date': '7'},
    {'day': 'Tue', 'date': '8'},
    {'day': 'Wed', 'date': '9'},
    {'day': 'Thu', 'date': '10'},
    {'day': 'Fri', 'date': '11'},
    {'day': 'Sat', 'date': '12'},
    {'day': 'Sun', 'date': '13'},
  ];

  Map<String, dynamic> _getTimeOfDayDetails() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return {
        'title': "Let's start your day",
        'subtitle': "Begin with a mindful morning reflections.",
        'currentLabel': "Morning",
        'color': const Color(0xFFFFD166), 
        'nextColor': const Color(0xFFFFE082),
        'illustrationType': 'morning',
      };
    } else if (hour >= 12 && hour < 17) {
      return {
        'title': "Good Afternoon",
        'subtitle': "Stay productive and keep moving forward.",
        'currentLabel': "Afternoon",
        'color': const Color(0xFFFFB74D), 
        'nextColor': const Color(0xFFFFCC80),
        'illustrationType': 'afternoon',
      };
    } else if (hour >= 17 && hour < 21) {
      return {
        'title': "Good Evening",
        'subtitle': "Take a moment to reflect on your day.",
        'currentLabel': "Evening",
        'color': const Color(0xFFFF8A65), 
        'nextColor': const Color(0xFFFFAB91),
        'illustrationType': 'evening',
      };
    } else {
      return {
        'title': "Good Night",
        'subtitle': "Prepare for a peaceful rest and reset.",
        'currentLabel': "Night",
        'color': const Color(0xFF3F51B5), 
        'nextColor': const Color(0xFF7986CB),
        'illustrationType': 'night',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED), // Off-white/cream background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              HorizontalCalendar(
                selectedDate: _selectedDate,
                taskDates: _userTasks.map((t) => t['date'] as DateTime).toList(),
                onDateSelected: (date) {
                  setState(() {
                    _selectedDateValue = date;
                  });
                },
              ),
              const SizedBox(height: 40),
              _buildJournalSection(),
              const SizedBox(height: 30),
              _buildQuickJournalSection(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFFB74D), // Yellow color from design
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black87, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi, $_userName',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () => widget.onProfileClick?.call(),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            backgroundImage: _userPhotoUrl != null 
                ? NetworkImage(_userPhotoUrl!) 
                : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildJournalSection() {
    final details = _getTimeOfDayDetails();
    final bool isNight = details['illustrationType'] == 'night';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Journal',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
              tooltip: 'Add Task',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: details['color'],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            details['title'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isNight ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details['subtitle'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isNight ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(double.infinity, 100),
                        painter: LandscapePainter(type: details['illustrationType']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 1,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: details['nextColor'],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      details['currentLabel'],
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickJournalSection() {
    final dailyTasks = _userTasks.where((task) {
      final taskDate = task['date'] as DateTime;
      final selectedDate = _selectedDate;
      return taskDate.year == selectedDate.year &&
             taskDate.month == selectedDate.month &&
             taskDate.day == selectedDate.day;
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Journal',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: _showAllTasksSheet,
              child: Text(
                'See all',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        dailyTasks.isEmpty 
          ? Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black12, width: 1),
              ),
              child: Center(
                child: Text(
                  'No tasks for this date',
                  style: GoogleFonts.outfit(color: Colors.black38),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dailyTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: _buildQuickCard(
                    title: task['title'],
                    subtitle: task['subtitle'],
                    tag: task['tag'],
                    color: task['color'],
                  ),
                )).toList(),
              ),
            ),
      ],
    );
  }

  void _showAllTasksSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F1ED),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Tasks',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _userTasks.isEmpty 
                ? Center(child: Text('No tasks added yet', style: GoogleFonts.outfit()))
                : ListView.builder(
                    itemCount: _userTasks.length,
                    itemBuilder: (context, index) {
                      final task = _userTasks[index];
                      // Use a default format if intl is not fully initialized for some reason
                      String dateStr = "${task['date'].day}/${task['date'].month}";
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: task['color'],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  Text(task['subtitle'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text(
                              dateStr,
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunshineIllustration(String type) {
    Color sunColor = const Color(0xFFFF9800);
    if (type == 'evening') sunColor = const Color(0xFFE64A19);
    if (type == 'night') sunColor = const Color(0xFFFFD54F);

    return Container(
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Simplified landscape representation
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: LandscapePainter(type: type),
            ),
          ),
          Positioned(
            bottom: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: sunColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (type == 'night')
                    BoxShadow(color: sunColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(width: 8, height: 4, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 70,
      color: Colors.white,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', true),
          _buildNavItem(Icons.explore_outlined, 'Explore', false),
          const SizedBox(width: 40), // Space for FAB
          _buildNavItem(Icons.assignment_outlined, 'Journey', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey[400],
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: isSelected ? Colors.black : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class LandscapePainter extends CustomPainter {
  final String type;
  LandscapePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background hills
    paint.color = const Color(0xFFE2B71B).withOpacity(0.5);
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.5, size.height * 0.8);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width, size.height * 0.9);
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Foreground grass
    paint.color = const Color(0xFF8DB600).withOpacity(0.8);
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.7, size.width * 0.6, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
