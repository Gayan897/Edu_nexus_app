import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../services/ews_service.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class EwsScreen extends StatelessWidget {
  const EwsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    final attendance = provider.attendance;
    final marks = provider.marks;
    final alerts = EwsService.generateAlerts(
      attendance: attendance,
      marks: marks,
      studentName: provider.studentName,
    );

    String alertMessage(EwsAlert alert) {
      if (provider.language == AppLanguage.sinhala) return alert.messageSi;
      if (provider.language == AppLanguage.tamil) return alert.messageTa;
      return alert.messageEn;
    }

    Color alertColor(EwsAlert alert) {
      switch (alert.severity) {
        case 'high': return SAMSColors.ewsAlert;
        case 'medium': return SAMSColors.ewsWarning;
        default: return SAMSColors.ewsSuccess;
      }
    }

    IconData alertIcon(EwsAlert alert) {
      switch (alert.type) {
        case 'attendance': return Icons.calendar_month_rounded;
        case 'marks': return Icons.assignment_rounded;
        default: return Icons.check_circle_rounded;
      }
    }

    final totalDays = attendance.length;
    final presentDays = attendance.where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late).length;
    final rate = totalDays > 0 ? presentDays / totalDays * 100 : 0.0;

    final term3Marks = marks.where((m) => m.term == 3).toList();
    final avgTerm3 = term3Marks.isNotEmpty
        ? term3Marks.fold(0.0, (s, m) => s + m.percentage) / term3Marks.length
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      appBar: AppBar(
        title: Text(SAMSStrings.earlyWarning),
        backgroundColor: SAMSColors.ewsWarning,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Academic Health overview
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SAMSStrings.academicHealth,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _MiniStat('Attendance', '${rate.toStringAsFixed(0)}%',
                                rate >= 85 ? SAMSColors.present : SAMSColors.late),
                            const SizedBox(width: 16),
                            _MiniStat('Term 3 Avg', '${avgTerm3.toStringAsFixed(0)}%',
                                avgTerm3 >= 75 ? SAMSColors.present : avgTerm3 >= 55 ? SAMSColors.late : SAMSColors.absent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alerts count
            Text(
              '${alerts.length} Alert${alerts.length != 1 ? 's' : ''} Found',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Alert cards
            ...alerts.map((alert) {
              final color = alertColor(alert);
              final icon = alertIcon(alert);
              final message = alertMessage(alert);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  alert.type.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 9,
                                    fontWeight: FontWeight.w800, color: color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (alert.subject != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  alert.subject!,
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13, height: 1.5,
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                            ),
                          ),
                          if (alert.value != null && alert.type != 'positive') ...[
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: alert.value! / 100,
                              backgroundColor: color.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${alert.value!.toStringAsFixed(0)}%',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: color),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Guidance note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SAMSColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SAMSColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: SAMSColors.primaryLight, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The Early Warning System monitors attendance and academic performance to help students and parents take timely action before term-end results.',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, height: 1.5,
                        color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70)),
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
