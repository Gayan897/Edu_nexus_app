import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDay = DateTime.now().weekday; // 1=Mon...5=Fri

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const _startTime = 7; // 7:00 AM

  String _periodTime(int period) {
    final start = _startTime + ((period - 1) * 45 ~/ 60);
    final startMin = ((period - 1) * 45) % 60;
    final end = start + ((startMin + 45) ~/ 60);
    final endMin = (startMin + 45) % 60;
    String fmt(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    // Rough schedule: 7:30 start with breaks
    final periods = [
      ('7:30', '8:15'), ('8:15', '9:00'), ('9:15', '10:00'), ('10:00', '10:45'),
      ('11:00', '11:45'), ('11:45', '12:30'), ('1:15', '2:00'),
    ];
    if (period >= 1 && period <= periods.length) {
      return '${periods[period - 1].$1} – ${periods[period - 1].$2}';
    }
    return fmt(start, startMin) + ' – ' + fmt(end, endMin);
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

    final timetable = provider.timetable;
    final studentClass = provider.studentClass;

    final todaySlots = timetable.where((s) => s.dayOfWeek == _selectedDay).toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    final substitutions = todaySlots.where((s) => s.hasSubstitution).toList();

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
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
                    SAMSStrings.todaysSchedule,
                    style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 18,
                      fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class ${studentClass.isNotEmpty ? studentClass : '-'} · ${todaySlots.length} Periods',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Substitution alert banner
          if (substitutions.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SAMSColors.late.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SAMSColors.late.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: SAMSColors.late, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        SAMSStrings.substituteAlert,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13,
                          fontWeight: FontWeight.w700, color: SAMSColors.late,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...substitutions.map((s) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• Period ${s.period}: ${s.subject} – ${SAMSStrings.substitute} ${s.substituteTeacher}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: SAMSColors.late),
                    ),
                  )),
                ],
              ),
            ),

          // Day selector
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final dayNum = i + 1;
                final isSelected = dayNum == _selectedDay;
                final isToday = dayNum == DateTime.now().weekday;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = dayNum),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5))
                          : null,
                    ),
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Period list
          Expanded(
            child: todaySlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 48, color: SAMSColors.textDarkSub),
                        const SizedBox(height: 12),
                        Text(
                          'No schedule for ${_days[_selectedDay - 1]}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: todaySlots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final slot = todaySlots[i];
                      return _PeriodCard(
                        slot: slot,
                        time: _periodTime(slot.period),
                        isDark: isDark,
                        isBreak: slot.period == 3 || slot.period == 5, // Approx break positions
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final TimetableSlot slot;
  final String time;
  final bool isDark;
  final bool isBreak;

  const _PeriodCard({required this.slot, required this.time, required this.isDark, required this.isBreak});

  Color get _subjectColor {
    switch (slot.subject) {
      case 'Mathematics': return SAMSColors.primary;
      case 'Science': return SAMSColors.secondary;
      case 'English': return const Color(0xFF0891B2);
      case 'Sinhala': return const Color(0xFF7C3AED);
      case 'History': return const Color(0xFFD97706);
      case 'ICT': return const Color(0xFF059669);
      case 'Art': return const Color(0xFFDB2777);
      default: return SAMSColors.textDarkSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = slot.hasSubstitution ? SAMSColors.late : _subjectColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        borderRadius: BorderRadius.circular(14),
        border: slot.hasSubstitution
            ? Border.all(color: SAMSColors.late.withOpacity(0.5), width: 1.5)
            : Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Period number
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${slot.period}',
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 14,
                  fontWeight: FontWeight.w800, color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Subject & teacher
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.subject,
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w700, color: color,
                      ),
                    ),
                    if (slot.hasSubstitution) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SAMSColors.late.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SUB',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 9,
                            fontWeight: FontWeight.w800, color: SAMSColors.late,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (slot.hasSubstitution) ...[
                  Text(
                    '${SAMSStrings.substitute} ${slot.substituteTeacher}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: SAMSColors.late, fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  Text(
                    slot.teacher,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Time
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 10,
              color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
            ),
          ),
        ],
      ),
    );
  }
}
