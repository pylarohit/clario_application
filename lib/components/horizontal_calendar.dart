import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HorizontalCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> taskDates;
  final Function(DateTime) onDateSelected;

  const HorizontalCalendar({
    super.key,
    required this.selectedDate,
    required this.taskDates,
    required this.onDateSelected,
  });

  @override
  State<HorizontalCalendar> createState() => _HorizontalCalendarState();
}

class _HorizontalCalendarState extends State<HorizontalCalendar> {
  late DateTime _startDate;
  final int _dayCount = 30; // Show 30 days for scrolling

  @override
  void initState() {
    super.initState();
    // Start from today
    _startDate = DateTime.now();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dayCount,
        itemBuilder: (context, index) {
          DateTime date = _startDate.add(Duration(days: index));
          bool isSelected = _isSameDay(date, widget.selectedDate);
          bool hasTask = widget.taskDates.any((taskDate) => _isSameDay(taskDate, date));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEE').format(date),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? const Color(0xFFFFB74D) 
                        : (hasTask ? const Color(0xFFE0E0E0) : Colors.white),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (hasTask)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
