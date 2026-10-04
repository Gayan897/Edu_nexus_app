import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late TabController _tabCtrl;
  bool _showAlert = false;
  String _alertMsg = '';
  Color _alertColor = SAMSColors.absent;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.attendance.isNotEmpty && provider.attendance.first.status == AttendanceStatus.absent) {
        _showFcmAlert(
          SAMSStrings.alertAbsent,
          '${provider.studentName} was marked ABSENT on ${provider.attendance.first.date}. Please contact the school if needed.',
          SAMSColors.absent,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showFcmAlert(String title, String msg, Color color) {
    setState(() {
      _showAlert = true;
      _alertMsg = msg;
      _alertColor = color;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showAlert = false);
    });
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return SAMSColors.present;
      case AttendanceStatus.absent: return SAMSColors.absent;
      case AttendanceStatus.late: return SAMSColors.late;
      case AttendanceStatus.excused: return SAMSColors.excused;
    }
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return SAMSStrings.present;
      case AttendanceStatus.absent: return SAMSStrings.absent;
      case AttendanceStatus.late: return SAMSStrings.late;
      case AttendanceStatus.excused: return SAMSStrings.excused;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    if (provider.dataLoading) {
      return Scaffold(
        backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final attendance = provider.attendance;

    // Build attendance map for calendar
    final attendanceMap = <DateTime, AttendanceStatus>{};
    for (final rec in attendance) {
      try {
        final parts = rec.date.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        attendanceMap[DateTime(d.year, d.month, d.day)] = rec.status;
      } catch (_) {}
    }

    final total = attendance.length;
    final present = attendance.where((a) => a.status == AttendanceStatus.present).length;
    final absent = attendance.where((a) => a.status == AttendanceStatus.absent).length;
    final late = attendance.where((a) => a.status == AttendanceStatus.late).length;
    final excused = attendance.where((a) => a.status == AttendanceStatus.excused).length;
    final rate = total > 0 ? (present + late) / total * 100 : 0.0;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: Column(
        children: [
          // ── FCM Alert overlay ───────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: _showAlert ? null : 0,
            child: _showAlert
                ? Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _alertColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _alertColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: _alertColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _alertMsg,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _alertColor, height: 1.4),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: _alertColor),
                          onPressed: () => setState(() => _showAlert = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Header ──────────────────────────────────────────────────────
          _AttendanceHeader(
            rate: rate,
            present: present,
            absent: absent,
            late: late,
            excused: excused,
            isDark: isDark,
          ),

          // ── Tab bar ─────────────────────────────────────────────────────
          Container(
            color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: SAMSColors.primaryLight,
              labelColor: SAMSColors.primaryLight,
              unselectedLabelColor: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
              tabs: const [
                Tab(text: 'Calendar'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Calendar tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _CalendarCard(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        attendanceMap: attendanceMap,
                        statusColor: _statusColor,
                        isDark: isDark,
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          setState(() => _focusedDay = focused);
                        },
                      ),
                      const SizedBox(height: 16),
                      _LegendRow(),
                    ],
                  ),
                ),

                // History tab
                attendance.isEmpty
                    ? const Center(child: Text('No attendance records found.', style: TextStyle(fontFamily: 'Inter')))
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: attendance.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final rec = attendance[i];
                    final color = _statusColor(rec.status);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            rec.date,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(rec.status),
                              style: TextStyle(
                                fontFamily: 'Inter', fontSize: 12,
                                fontWeight: FontWeight.w600, color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header card with donut-style summary ────────────────────────────────────
class _AttendanceHeader extends StatelessWidget {
  final double rate;
  final int present, absent, late, excused;
  final bool isDark;

  const _AttendanceHeader({
    required this.rate, required this.present,
    required this.absent, required this.late,
    required this.excused, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SAMSStrings.attendanceHistory,
              style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Rate circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80, height: 80,
                      child: CircularProgressIndicator(
                        value: rate / 100,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(
                          rate >= 85 ? SAMSColors.present : rate >= 75 ? SAMSColors.late : SAMSColors.absent,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${rate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 18,
                            fontWeight: FontWeight.w800, color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Rate',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Status counts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusRow(SAMSColors.present, SAMSStrings.present, present),
                      _StatusRow(SAMSColors.absent, SAMSStrings.absent, absent),
                      _StatusRow(SAMSColors.late, SAMSStrings.late, late),
                      _StatusRow(SAMSColors.excused, SAMSStrings.excused, excused),
                    ],
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

class _StatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _StatusRow(this.color, this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
          const Spacer(),
          Text('$count days', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Calendar card ────────────────────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, AttendanceStatus> attendanceMap;
  final Color Function(AttendanceStatus) statusColor;
  final bool isDark;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.attendanceMap,
    required this.statusColor,
    required this.isDark,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            fontFamily: 'Inter', color: isDark ? Colors.white : Colors.black87,
          ),
          weekendTextStyle: TextStyle(
            fontFamily: 'Inter', color: isDark ? Colors.white60 : Colors.black45,
          ),
          selectedDecoration: const BoxDecoration(
            color: SAMSColors.primary, shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: SAMSColors.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w700,
            fontSize: 15, color: isDark ? Colors.white : Colors.black87,
          ),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? SAMSColors.textDarkSub.withOpacity(0.6) : SAMSColors.textLightSub.withOpacity(0.6),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            final key = DateTime(day.year, day.month, day.day);
            if (attendanceMap.containsKey(key)) {
              final status = attendanceMap[key]!;
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
          defaultBuilder: (context, day, focusedDay) {
            final key = DateTime(day.year, day.month, day.day);
            if (attendanceMap.containsKey(key)) {
              final status = attendanceMap[key]!;
              return Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor(status).withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 13,
                      color: statusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (SAMSColors.present, SAMSStrings.present),
      (SAMSColors.absent, SAMSStrings.absent),
      (SAMSColors.late, SAMSStrings.late),
      (SAMSColors.excused, SAMSStrings.excused),
    ];
    return Wrap(
      spacing: 16, runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(item.$2, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
        ],
      )).toList(),
    );
  }
}
