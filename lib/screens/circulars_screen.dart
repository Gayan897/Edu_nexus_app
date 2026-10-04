import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class CircularsScreen extends StatefulWidget {
  const CircularsScreen({super.key});

  @override
  State<CircularsScreen> createState() => _CircularsScreenState();
}

class _CircularsScreenState extends State<CircularsScreen> {
  String _filterGrade = 'all';
  String _filterCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final lang = provider.language;

    if (provider.dataLoading) {
      return Scaffold(
        backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
        appBar: AppBar(
          title: Text(SAMSStrings.circulars),
          backgroundColor: SAMSColors.secondary,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allCirculars = provider.notices;
    final filtered = allCirculars.where((c) {
      final gradeMatch = _filterGrade == 'all' || c.targetGrade == null || c.targetGrade == _filterGrade;
      final catMatch = _filterCategory == 'all' || c.category == _filterCategory;
      return gradeMatch && catMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      appBar: AppBar(
        title: Text(SAMSStrings.circulars),
        backgroundColor: SAMSColors.secondary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.refreshData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grade filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: SAMSStrings.allGrades, value: 'all', selected: _filterGrade, onTap: (v) => setState(() => _filterGrade = v), color: SAMSColors.secondary),
                      _FilterChip(label: 'Grade 10', value: '10', selected: _filterGrade, onTap: (v) => setState(() => _filterGrade = v), color: SAMSColors.secondary),
                      _FilterChip(label: 'Grade 11', value: '11', selected: _filterGrade, onTap: (v) => setState(() => _filterGrade = v), color: SAMSColors.secondary),
                      _FilterChip(label: 'Grade 12', value: '12', selected: _filterGrade, onTap: (v) => setState(() => _filterGrade = v), color: SAMSColors.secondary),
                      _FilterChip(label: 'Grade 13', value: '13', selected: _filterGrade, onTap: (v) => setState(() => _filterGrade = v), color: SAMSColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', value: 'all', selected: _filterCategory, onTap: (v) => setState(() => _filterCategory = v), color: SAMSColors.primary),
                      _FilterChip(label: 'Academic', value: 'academic', selected: _filterCategory, onTap: (v) => setState(() => _filterCategory = v), color: SAMSColors.primary),
                      _FilterChip(label: 'Exam', value: 'exam', selected: _filterCategory, onTap: (v) => setState(() => _filterCategory = v), color: SAMSColors.absent),
                      _FilterChip(label: 'Event', value: 'event', selected: _filterCategory, onTap: (v) => setState(() => _filterCategory = v), color: SAMSColors.secondary),
                      _FilterChip(label: 'Meeting', value: 'meeting', selected: _filterCategory, onTap: (v) => setState(() => _filterCategory = v), color: SAMSColors.late),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} ${filtered.length == 1 ? 'circular' : 'circulars'}',
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                ),
              ],
            ),
          ),

          // Circulars list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: SAMSColors.textDarkSub),
                        const SizedBox(height: 12),
                        Text(SAMSStrings.noAnnouncements, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CircularCard(
                      notice: filtered[i],
                      lang: lang,
                      isDark: isDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, selected;
  final Color color;
  final void Function(String) onTap;

  const _FilterChip({
    required this.label, required this.value,
    required this.selected, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _CircularCard extends StatefulWidget {
  final CircularNotice notice;
  final AppLanguage lang;
  final bool isDark;

  const _CircularCard({required this.notice, required this.lang, required this.isDark});

  @override
  State<_CircularCard> createState() => _CircularCardState();
}

class _CircularCardState extends State<_CircularCard> {
  bool _expanded = false;

  String get title {
    if (widget.lang == AppLanguage.sinhala) return widget.notice.titleSi;
    if (widget.lang == AppLanguage.tamil) return widget.notice.titleTa;
    return widget.notice.titleEn;
  }

  String get body {
    if (widget.lang == AppLanguage.sinhala) return widget.notice.bodySi;
    if (widget.lang == AppLanguage.tamil) return widget.notice.bodyTa;
    return widget.notice.bodyEn;
  }

  Color get categoryColor {
    switch (widget.notice.category) {
      case 'exam': return SAMSColors.absent;
      case 'event': return SAMSColors.secondary;
      case 'meeting': return SAMSColors.late;
      case 'academic': return SAMSColors.primary;
      default: return SAMSColors.primaryLight;
    }
  }

  IconData get categoryIcon {
    switch (widget.notice.category) {
      case 'exam': return Icons.assignment_rounded;
      case 'event': return Icons.event_rounded;
      case 'meeting': return Icons.groups_rounded;
      case 'academic': return Icons.school_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.notice.targetGrade != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Grade ${widget.notice.targetGrade}',
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 9,
                                  fontWeight: FontWeight.w700, color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.notice.category.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 9,
                              fontWeight: FontWeight.w700, color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 13, height: 1.6,
                        color: widget.isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub),
                        const SizedBox(width: 4),
                        Text(
                          widget.notice.date,
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 11,
                            color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
