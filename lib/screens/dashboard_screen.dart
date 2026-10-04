import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../services/notification_service.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  bool _hasCheckedAlert = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkImmediateParentAlert();
    });
  }

  void _checkImmediateParentAlert() {
    if (!mounted || _hasCheckedAlert) return;
    final provider = context.read<AppProvider>();
    if (!provider.isParent) return;

    final urgentNotifs = provider.parentNotifications.where(
      (n) => !n.read && (n.status == AttendanceStatus.absent || n.status == AttendanceStatus.late || n.priority == 'urgent'),
    ).toList();

    if (urgentNotifs.isNotEmpty) {
      _hasCheckedAlert = true;
      _showUrgentAttendanceDialog(context, provider, urgentNotifs.first);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return SAMSStrings.goodMorning;
    if (h < 17) return SAMSStrings.goodAfternoon;
    return SAMSStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final attendance = provider.attendance;
    final marks = provider.marks;

    // React to real-time incoming alert emitted from stream
    final incomingAlert = provider.latestIncomingAlert;
    if (incomingAlert != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.latestIncomingAlert != null) {
          final alertToShow = provider.latestIncomingAlert!;
          provider.clearLatestIncomingAlert();
          _showUrgentAttendanceDialog(context, provider, alertToShow);
        }
      });
    }

    // Stats
    final totalDays = attendance.length;
    final presentDays = attendance.where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.late).length;
    final attRate = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

    // Latest term average
    final term3Marks = marks.where((m) => m.term == 3).toList();
    final avgTerm3 = term3Marks.isNotEmpty
        ? term3Marks.fold(0.0, (s, m) => s + m.percentage) / term3Marks.length
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            // ── App Bar Hero ─────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: SAMSColors.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(top: -50, right: -50, child: _bubble(180, 0.06)),
                      Positioned(bottom: -30, left: -30, child: _bubble(120, 0.05)),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    child: Text(
                                      provider.studentName.isNotEmpty
                                          ? provider.studentName[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20, fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_greeting()},',
                                          style: TextStyle(
                                            fontFamily: 'Inter', fontSize: 13,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        Text(
                                          provider.studentName,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins', fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${SAMSStrings.grade} ${provider.studentGrade} · ${provider.studentClass}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter', fontSize: 11,
                                            color: Colors.white, fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Material(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => _showNotificationsBottomSheet(context, provider),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.notifications_active_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (provider.unreadParentNotificationsCount > 0)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFEF4444),
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                                child: Text(
                                                  '${provider.unreadParentNotificationsCount}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _StatPill(
                                    label: SAMSStrings.attendanceRate,
                                    value: '${attRate.toStringAsFixed(0)}%',
                                    color: attRate >= 85
                                        ? SAMSColors.present
                                        : attRate >= 75
                                            ? SAMSColors.late
                                            : SAMSColors.absent,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatPill(
                                    label: SAMSStrings.latestTerm,
                                    value: '${avgTerm3.toStringAsFixed(0)}%',
                                    color: avgTerm3 >= 75
                                        ? SAMSColors.present
                                        : avgTerm3 >= 55
                                            ? SAMSColors.late
                                            : SAMSColors.absent,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatPill(
                                    label: SAMSStrings.classRank,
                                    value: '#3',
                                    color: SAMSColors.secondaryLight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body content ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Role badge
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: provider.isParent
                          ? SAMSColors.secondary.withOpacity(0.12)
                          : SAMSColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.isParent
                            ? SAMSColors.secondary.withOpacity(0.3)
                            : SAMSColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.isParent ? Icons.family_restroom_rounded : Icons.school_rounded,
                          color: provider.isParent ? SAMSColors.secondary : SAMSColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          provider.isParent
                              ? '👨‍👩‍👦 ${SAMSStrings.parent} – Monitoring ${provider.studentName}'
                              : '🎓 ${SAMSStrings.student} – ${provider.user?.name ?? ""}',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                            color: provider.isParent ? SAMSColors.secondary : SAMSColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Real-time Attendance Notification Banner (for Parents & Students)
                  if (provider.parentNotifications.isNotEmpty) ...[
                    _ParentAttendanceNotificationCard(
                      notification: provider.parentNotifications.first,
                      isDark: isDark,
                      unreadCount: provider.unreadParentNotificationsCount,
                      onTap: () => _showNotificationsBottomSheet(context, provider),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Quick stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _QuickStatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: SAMSStrings.present,
                        value: '$presentDays',
                        sublabel: 'days this month',
                        color: SAMSColors.present,
                        isDark: isDark,
                      ),
                      _QuickStatCard(
                        icon: Icons.cancel_outlined,
                        label: SAMSStrings.absent,
                        value: '${attendance.where((a) => a.status == AttendanceStatus.absent).length}',
                        sublabel: 'days this month',
                        color: SAMSColors.absent,
                        isDark: isDark,
                      ),
                      _QuickStatCard(
                        icon: Icons.schedule_rounded,
                        label: SAMSStrings.late,
                        value: '${attendance.where((a) => a.status == AttendanceStatus.late).length}',
                        sublabel: 'late arrivals',
                        color: SAMSColors.late,
                        isDark: isDark,
                      ),
                      _QuickStatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Best Subject',
                        value: 'ICT',
                        sublabel: '97% – Term 3',
                        color: SAMSColors.secondaryLight,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recent notices
                  _SectionHeader(title: SAMSStrings.recentNotices),
                  const SizedBox(height: 10),
                  if (provider.notices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          SAMSStrings.noAnnouncements,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                          ),
                        ),
                      ),
                    )
                  else
                    ...provider.notices.take(3).map((c) => _NoticeCard(
                      notice: c,
                      lang: provider.language,
                      isDark: isDark,
                    )),
                  const SizedBox(height: 20),

                  // FCM Alert Demo
                  _FcmAlertBanner(isDark: isDark),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white70)),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sublabel;
  final Color color;
  final bool isDark;

  const _QuickStatCard({
    required this.icon, required this.label, required this.value,
    required this.sublabel, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins', fontSize: 24,
              fontWeight: FontWeight.w800, color: color,
            ),
          ),
          Text(
            sublabel,
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

class _NoticeCard extends StatelessWidget {
  final CircularNotice notice;
  final AppLanguage lang;
  final bool isDark;

  const _NoticeCard({required this.notice, required this.lang, required this.isDark});

  String get title {
    if (lang == AppLanguage.sinhala) return notice.titleSi;
    if (lang == AppLanguage.tamil) return notice.titleTa;
    return notice.titleEn;
  }

  String get body {
    if (lang == AppLanguage.sinhala) return notice.bodySi;
    if (lang == AppLanguage.tamil) return notice.bodyTa;
    return notice.bodyEn;
  }

  Color get categoryColor {
    switch (notice.category) {
      case 'exam': return SAMSColors.absent;
      case 'event': return SAMSColors.secondary;
      case 'meeting': return SAMSColors.late;
      default: return SAMSColors.primaryLight;
    }
  }

  IconData get categoryIcon {
    switch (notice.category) {
      case 'exam': return Icons.assignment_rounded;
      case 'event': return Icons.event_rounded;
      case 'meeting': return Icons.groups_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: categoryColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12, height: 1.4,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  notice.date,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 10,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FcmAlertBanner extends StatefulWidget {
  final bool isDark;
  const _FcmAlertBanner({required this.isDark});

  @override
  State<_FcmAlertBanner> createState() => _FcmAlertBannerState();
}

class _FcmAlertBannerState extends State<_FcmAlertBanner> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SAMSColors.absent.withOpacity(0.08 + _pulse.value * 0.04),
              SAMSColors.late.withOpacity(0.06 + _pulse.value * 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SAMSColors.absent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SAMSColors.absent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: SAMSColors.absent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔴 FCM Attendance Alert',
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: FontWeight.w700, color: SAMSColors.absent,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Kasun was marked ABSENT today (Aug 11). Please check with the school if this is unexpected.',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: Colors.white70, height: 1.4,
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

// ─── Real-Time Parent Attendance Notification Card ───────────────────────────
class _ParentAttendanceNotificationCard extends StatelessWidget {
  final ParentNotification notification;
  final bool isDark;
  final int unreadCount;
  final VoidCallback onTap;

  const _ParentAttendanceNotificationCard({
    required this.notification,
    required this.isDark,
    required this.unreadCount,
    required this.onTap,
  });

  Color _getStatusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return SAMSColors.present;
      case AttendanceStatus.absent: return SAMSColors.absent;
      case AttendanceStatus.late: return SAMSColors.late;
      case AttendanceStatus.excused: return SAMSColors.excused;
    }
  }

  IconData _getStatusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return Icons.check_circle_rounded;
      case AttendanceStatus.absent: return Icons.warning_amber_rounded;
      case AttendanceStatus.late: return Icons.access_time_filled_rounded;
      case AttendanceStatus.excused: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(notification.status);
    final statusIcon = _getStatusIcon(notification.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? SAMSColors.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.status == AttendanceStatus.absent
                ? SAMSColors.absent.withOpacity(0.5)
                : statusColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            SAMSStrings.latestAttendanceUpdate,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!notification.read) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        notification.date,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    notification.status.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notification.message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? SAMSColors.textDark : SAMSColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (notification.teacherName != null && notification.teacherName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SAMSStrings.recordedByTeacher}: ${notification.teacherName}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                  Text(
                    'View all ${unreadCount > 0 ? "($unreadCount unread)" : ""} →',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SAMSColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Modal Bottom Sheet for All Parent Attendance Notifications ──────────────
void _showNotificationsBottomSheet(BuildContext context, AppProvider provider) {
  final isDark = provider.isDark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5)),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: SAMSColors.primaryLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      SAMSStrings.parentNotifications,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (provider.unreadParentNotificationsCount > 0)
                    TextButton(
                      onPressed: () {
                        provider.markAllNotificationsAsRead();
                      },
                      child: Text(
                        SAMSStrings.markAllRead,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SAMSColors.primaryLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Quick Action: Test Real System Notification
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: SAMSColors.primaryLight.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SAMSColors.primaryLight.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phonelink_ring_rounded, size: 18, color: SAMSColors.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Push alerts active (lock screen & status bar)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? SAMSColors.textDark : SAMSColors.textLight,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: SAMSColors.primaryLight.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await NotificationService.instance.sendTestNotification(
                          studentName: provider.studentName.isNotEmpty
                              ? provider.studentName
                              : 'Student',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔔 Real system notification sent! Check your notification bar.'),
                              backgroundColor: Color(0xFF1E3A8A),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 12, color: SAMSColors.primaryLight),
                      label: const Text(
                        'Test Alert',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SAMSColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 16),

            // List of Notifications
            Expanded(
              child: provider.parentNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            SAMSStrings.noNotifications,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.parentNotifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = provider.parentNotifications[index];
                        final statusColor = notif.status == AttendanceStatus.present
                            ? SAMSColors.present
                            : notif.status == AttendanceStatus.absent
                                ? SAMSColors.absent
                                : notif.status == AttendanceStatus.late
                                    ? SAMSColors.late
                                    : SAMSColors.excused;

                        Future<bool> confirmDelete() async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              title: const Text(
                                'Delete Notification',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700),
                              ),
                              content: const Text(
                                'Remove this notification permanently?',
                                style: TextStyle(fontFamily: 'Inter'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                        color: SAMSColors.absent,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ) ?? false;
                        }

                        return Dismissible(
                          key: ValueKey(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: SAMSColors.absent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: SAMSColors.absent,
                              size: 22,
                            ),
                          ),
                          confirmDismiss: (_) => confirmDelete(),
                          onDismissed: (_) => provider.deleteNotification(notif.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: notif.read ? Colors.transparent : statusColor.withOpacity(0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notif.status == AttendanceStatus.present
                                        ? Icons.check_circle_rounded
                                        : notif.status == AttendanceStatus.absent
                                            ? Icons.cancel_rounded
                                            : notif.status == AttendanceStatus.late
                                                ? Icons.access_time_filled_rounded
                                                : Icons.info_rounded,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            notif.date,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: isDark ? SAMSColors.textDark : SAMSColors.textLight,
                                        ),
                                      ),
                                      if (notif.teacherName != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '${SAMSStrings.recordedByTeacher}: ${notif.teacherName}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // ── Action buttons ───────────────────────────
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!notif.read)
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        icon: const Icon(Icons.check_circle_outline,
                                            size: 18, color: SAMSColors.primaryLight),
                                        tooltip: 'Mark as read',
                                        onPressed: () => provider.markNotificationAsRead(notif.id),
                                      ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: SAMSColors.absent.withOpacity(0.7),
                                      ),
                                      tooltip: 'Delete notification',
                                      onPressed: () async {
                                        final ok = await confirmDelete();
                                        if (ok && context.mounted) {
                                          provider.deleteNotification(notif.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

// ─── Immediate Urgent Parent Attendance Alert Dialog ──────────────────────────
void _showUrgentAttendanceDialog(BuildContext context, AppProvider provider, ParentNotification notif) {
  final isDark = provider.isDark;
  final isAbsent = notif.status == AttendanceStatus.absent;
  final alertColor = isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
  final alertTitle = isAbsent ? '🚨 URGENT: ABSENT NOTICE' : '⚠️ ATTENDANCE: LATE NOTICE';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? SAMSColors.bgDarkCard : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Siren Icon with pulsing background
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: alertColor.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  isAbsent ? Icons.notification_important_rounded : Icons.access_time_filled_rounded,
                  color: alertColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                alertTitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: alertColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Student: ${notif.studentName}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: alertColor.withOpacity(0.2)),
                ),
                child: Text(
                  notif.message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? SAMSColors.textDark : SAMSColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text('Contact School', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.markNotificationAsRead(notif.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling School Office: +94 11 234 5678')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Acknowledge', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                      onPressed: () {
                        provider.markNotificationAsRead(notif.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
