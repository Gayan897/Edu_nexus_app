import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showReportCard(BuildContext context, List<TermMark> marks, bool isDark) {
    HapticFeedback.mediumImpact();
    final terms = marks.map((m) => m.term).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportCardSheet(
        marks: marks,
        terms: terms,
        isDark: isDark,
        markColor: _markColor,
        grade: _grade,
      ),
    );
  }


  Color _markColor(double pct) {
    if (pct >= 75) return SAMSColors.present;
    if (pct >= 55) return SAMSColors.late;
    return SAMSColors.absent;
  }

  String _grade(double pct) {
    if (pct >= 75) return 'A';
    if (pct >= 65) return 'B';
    if (pct >= 55) return 'C';
    if (pct >= 45) return 'S';
    return 'F';
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

    final marks = provider.marks;
    final avg = marks.isNotEmpty
        ? marks.fold(0.0, (s, m) => s + m.percentage) / marks.length
        : 0.0;
    final bestSubjectMark = marks.isNotEmpty
        ? marks.reduce((a, b) => a.percentage >= b.percentage ? a : b)
        : null;
    final bestSubjectText = bestSubjectMark != null
        ? '${bestSubjectMark.subject} (${bestSubjectMark.percentage.toStringAsFixed(0)}%)'
        : '–';
    final totalSubjects = marks.map((m) => m.subject).toSet().length;
    final termsRecorded = marks.map((m) => m.term).toSet().length;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        SAMSStrings.academicProgress,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 18,
                          fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
                      if (marks.isNotEmpty)
                        Material(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showReportCard(context, marks, isDark),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 5),
                                  Text(
                                    'Report Card',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeaderStat('Overall Avg', '${avg.toStringAsFixed(1)}%', SAMSColors.secondaryLight),
                      const SizedBox(width: 12),
                      _HeaderStat('Subjects', '$totalSubjects', Colors.amberAccent),
                      const SizedBox(width: 12),
                      _HeaderStat('Terms', '$termsRecorded', Colors.lightBlueAccent),
                      const SizedBox(width: 12),
                      _HeaderStat('Best', bestSubjectText, Colors.pinkAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          Container(
            color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: SAMSColors.secondary,
              labelColor: SAMSColors.secondary,
              unselectedLabelColor: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Marks'),
                Tab(text: 'Charts'),
                Tab(text: 'Subjects'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: marks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined, size: 52,
                              color: SAMSColors.secondary.withOpacity(0.4)),
                          const SizedBox(height: 14),
                          Text('No marks found.',
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? SAMSColors.textDark : SAMSColors.textLight,
                            )),
                          const SizedBox(height: 6),
                          Text('Ask your teacher to enter marks in the web portal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                            )),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Marks table tab ───────────────────────────────────────
                _MarksTab(marks: marks, isDark: isDark, markColor: _markColor, grade: _grade),

                // ── Charts tab ────────────────────────────────────────────
                _ChartsTab(marks: marks, isDark: isDark, markColor: _markColor),

                // ── Subjects tab ──────────────────────────────────────────
                _SubjectsTab(marks: marks, isDark: isDark, markColor: _markColor, grade: _grade),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white60)),
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _MarksTab extends StatefulWidget {
  final List<TermMark> marks;
  final bool isDark;
  final Color Function(double) markColor;
  final String Function(double) grade;

  const _MarksTab({
    required this.marks,
    required this.isDark,
    required this.markColor,
    required this.grade,
  });

  @override
  State<_MarksTab> createState() => _MarksTabState();
}

class _MarksTabState extends State<_MarksTab> {
  int? _selectedTerm; // null = All Terms

  @override
  void initState() {
    super.initState();
    _initSelectedTerm();
  }

  @override
  void didUpdateWidget(_MarksTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marks != widget.marks) {
      _initSelectedTerm();
    }
  }

  void _initSelectedTerm() {
    final recordedTerms = widget.marks.map((m) => m.term).toSet().toList()..sort();
    if (recordedTerms.isNotEmpty) {
      if (_selectedTerm == null || !recordedTerms.contains(_selectedTerm)) {
        // Default to latest available term
        _selectedTerm = recordedTerms.last;
      }
    } else {
      _selectedTerm = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataTerms = widget.marks.map((m) => m.term).toSet();
    final availableTerms = {1, 2, 3, ...dataTerms}.toList()..sort();

    return Column(
      children: [
        // ── Term Selection Bar ───────────────────────────────────────────
        _buildTermSelectorBar(availableTerms),

        // ── Term Marks Body ──────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04), end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _selectedTerm != null
                ? _buildSingleTermView(_selectedTerm!, key: ValueKey('term_$_selectedTerm'))
                : _buildAllTermsView(availableTerms, key: const ValueKey('all_terms')),
          ),
        ),
      ],
    );
  }

  Widget _buildTermSelectorBar(List<int> availableTerms) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // All Terms chip
            _buildSelectorChip(
              label: SAMSStrings.allTerms,
              icon: Icons.auto_awesome_mosaic_rounded,
              isSelected: _selectedTerm == null,
              onTap: () => setState(() => _selectedTerm = null),
            ),
            const SizedBox(width: 8),
            // Individual term chips (Term 1, Term 2, Term 3)
            ...availableTerms.map((t) {
              final isSel = _selectedTerm == t;
              final tMarks = widget.marks.where((m) => m.term == t).toList();
              final avg = tMarks.isNotEmpty
                  ? tMarks.fold(0.0, (s, m) => s + m.percentage) / tMarks.length
                  : null;

              String termName;
              if (t == 1) {
                termName = SAMSStrings.term1;
              } else if (t == 2) {
                termName = SAMSStrings.term2;
              } else if (t == 3) {
                termName = SAMSStrings.term3;
              } else {
                termName = 'Term $t';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildSelectorChip(
                  label: termName,
                  icon: Icons.calendar_today_rounded,
                  badge: avg != null ? '${avg.toStringAsFixed(0)}%' : null,
                  isSelected: isSel,
                  onTap: () => setState(() => _selectedTerm = t),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorChip({
    required String label,
    required IconData icon,
    String? badge,
    required bool isSelected,
    bool hasData = true,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? SAMSColors.secondary
                : (isDark ? SAMSColors.bgDarkSurface : SAMSColors.bgLightSurface),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? SAMSColors.secondary
                  : (hasData
                      ? (isDark ? Colors.white24 : Colors.black12)
                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SAMSColors.secondary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (hasData
                        ? (isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub)
                        : (isDark ? Colors.white30 : Colors.black26)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (hasData
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.black38)),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : SAMSColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTermView(int term, {Key? key}) {
    final termMarks = widget.marks.where((m) => m.term == term).toList();

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Summary Performance Card for this term
        _buildTermSummaryCard(term, termMarks),

        if (termMarks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${SAMSStrings.subjects} (${termMarks.length})',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Sorted by mark',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                ),
              ],
            ),
          ),
          ...([...termMarks]..sort((a, b) => b.percentage.compareTo(a.percentage)))
              .asMap().entries.map((e) => _buildSubjectCard(e.value, index: e.key)),
        ],
      ],
    );
  }

  Widget _buildAllTermsView(List<int> availableTerms, {Key? key}) {
    final termsWithMarks = availableTerms
        .where((t) => widget.marks.any((m) => m.term == t))
        .toList();

    if (termsWithMarks.isEmpty) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_late_outlined, size: 48, color: SAMSColors.secondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                SAMSStrings.noMarksForTerm,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final totalScored = widget.marks.fold(0.0, (s, m) => s + m.marks);
    final totalPossible = widget.marks.fold(0.0, (s, m) => s + m.maxMarks);
    final overallAvg = totalPossible > 0 ? (totalScored / totalPossible * 100) : 0.0;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Overall Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SAMSColors.secondary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SAMSColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: SAMSColors.secondary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Recorded Terms (${termsWithMarks.length})',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cumulative Score: ${totalScored.toInt()} / ${totalPossible.toInt()} pts',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${overallAvg.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.markColor(overallAvg),
                    ),
                  ),
                  Text(
                    'Overall',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Grouped by term
        ...termsWithMarks.map((t) {
          final tMarks = widget.marks.where((m) => m.term == t).toList()
            ..sort((a, b) => b.percentage.compareTo(a.percentage));
          final tAvg = tMarks.isNotEmpty
              ? tMarks.fold(0.0, (s, m) => s + m.percentage) / tMarks.length
              : 0.0;
          final tColor = widget.markColor(tAvg);

          String termName;
          if (t == 1) {
            termName = SAMSStrings.term1;
          } else if (t == 2) {
            termName = SAMSStrings.term2;
          } else if (t == 3) {
            termName = SAMSStrings.term3;
          } else {
            termName = 'Term $t';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: SAMSColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            termName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SAMSColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tMarks.length} ${SAMSStrings.subjects}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Avg: ${tAvg.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...tMarks.asMap().entries.map((e) => _buildSubjectCard(e.value, index: e.key)),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTermSummaryCard(int term, List<TermMark> termMarks) {
    String termTitle;
    if (term == 1) {
      termTitle = SAMSStrings.term1;
    } else if (term == 2) {
      termTitle = SAMSStrings.term2;
    } else if (term == 3) {
      termTitle = SAMSStrings.term3;
    } else {
      termTitle = 'Term $term';
    }

    if (termMarks.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_late_outlined, size: 44, color: SAMSColors.secondary.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              'No marks recorded for $termTitle yet',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SAMSStrings.noMarksForTerm,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
              ),
            ),
          ],
        ),
      );
    }

    final totalScore = termMarks.fold(0.0, (s, m) => s + m.marks);
    final totalMax = termMarks.fold(0.0, (s, m) => s + m.maxMarks);
    final termAvg = totalMax > 0 ? (totalScore / totalMax * 100) : 0.0;
    final termColor = widget.markColor(termAvg);
    final termGrade = widget.grade(termAvg);

    final bestSubject = termMarks.reduce((a, b) => a.percentage >= b.percentage ? a : b);
    final lowestSubject = termMarks.reduce((a, b) => a.percentage <= b.percentage ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
              ? [const Color(0xFF134E4A), const Color(0xFF0F766E)]
              : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        termTitle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Grade $termGrade',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: termColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${termAvg.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      SAMSStrings.termAverage,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStatCol(
                        label: SAMSStrings.totalMarks,
                        value: '${totalScore.toInt()} / ${totalMax.toInt()}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryStatCol(
                        label: SAMSStrings.topSubject,
                        value: '${bestSubject.subject} (${bestSubject.percentage.toStringAsFixed(0)}%)',
                      ),
                    ),
                    if (termMarks.length > 1)
                      Expanded(
                        child: _SummaryStatCol(
                          label: SAMSStrings.needsFocus,
                          value: '${lowestSubject.subject} (${lowestSubject.percentage.toStringAsFixed(0)}%)',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(TermMark m, {int index = 0}) {
    final isDark = widget.isDark;
    final pct = m.percentage;
    final color = widget.markColor(pct);
    final letterGrade = widget.grade(pct);

    String remark = 'Needs Improvement';
    if (pct >= 75) {
      remark = 'Distinction';
    } else if (pct >= 65) {
      remark = 'Very Good';
    } else if (pct >= 55) {
      remark = 'Credit';
    } else if (pct >= 45) {
      remark = 'Ordinary Pass';
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('${m.subject}_${m.term}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Grade badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  letterGrade,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Subject Name + Remark + Animated Progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.subject,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          remark,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: (pct / 100).clamp(0.0, 1.0)),
                    duration: Duration(milliseconds: 600 + index * 50),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: v,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${m.marks.toInt()}/${m.maxMarks.toInt()}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
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

class _SummaryStatCol extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ChartsTab extends StatefulWidget {
  final List<TermMark> marks;
  final bool isDark;
  final Color Function(double) markColor;

  const _ChartsTab({required this.marks, required this.isDark, required this.markColor});

  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  String? _selectedSubject;
  int? _selectedChartTerm;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void didUpdateWidget(_ChartsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marks != widget.marks) _initState();
  }

  void _initState() {
    final subjects = widget.marks.map((m) => m.subject).toSet().toList();
    if (_selectedSubject == null || !subjects.contains(_selectedSubject)) {
      _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
    }
    final recordedTerms = widget.marks.map((m) => m.term).toSet().toList()..sort();
    if (recordedTerms.isNotEmpty) {
      if (_selectedChartTerm == null || !recordedTerms.contains(_selectedChartTerm)) {
        _selectedChartTerm = recordedTerms.last;
      }
    } else {
      _selectedChartTerm = 1;
    }
  }

  String _termNameChart(int t) {
    if (t == 1) return SAMSStrings.term1;
    if (t == 2) return SAMSStrings.term2;
    if (t == 3) return SAMSStrings.term3;
    return 'Term $t';
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.marks.map((m) => m.subject).toSet().toList();
    if (_selectedSubject == null) return const Center(child: Text('No data'));

    final allTerms = widget.marks.map((m) => m.term).toSet().toList()..sort();
    final chartTerms = allTerms.length >= 2 ? allTerms
        : ({...allTerms, 1, 2, 3}).toList()..sort();
    final availableChartTerms = ({1, 2, 3, ...allTerms}).toList()..sort();

    final termData = chartTerms.map((t) {
      final mark = widget.marks.firstWhere(
        (m) => m.subject == _selectedSubject && m.term == t,
        orElse: () => TermMark(studentId: '', subject: _selectedSubject!, term: t, marks: 0, maxMarks: 100),
      );
      return FlSpot(t.toDouble(), mark.percentage);
    }).toList();

    final chartMarks = widget.marks.where((m) => m.term == _selectedChartTerm).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subjects.map((s) {
                final isSelected = s == _selectedSubject;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubject = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? SAMSColors.secondary : (widget.isDark ? SAMSColors.bgDarkSurface : SAMSColors.bgLightSurface),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : (widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Line chart
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
            decoration: BoxDecoration(
              color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 10,
                          color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _termNameChart(v.toInt()),
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 10,
                            color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: chartTerms.first.toDouble(),
                maxX: chartTerms.last.toDouble(),
                minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: termData,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: SAMSColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 6,
                        color: SAMSColors.secondary,
                        strokeWidth: 2.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: SAMSColors.secondary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // All subjects bar chart header with dynamic term selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Subjects – ${_termNameChart(_selectedChartTerm ?? 1)}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Row(
                children: availableChartTerms.map((t) {
                  final isSel = _selectedChartTerm == t;
                  final hasData = widget.marks.any((m) => m.term == t);
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedChartTerm = t); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? SAMSColors.secondary : (widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? SAMSColors.secondary
                              : (hasData ? (widget.isDark ? Colors.white24 : Colors.black12)
                                         : (widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
                        ),
                      ),
                      child: Text(
                        'T$t',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white
                              : (hasData ? (widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub)
                                         : (widget.isDark ? Colors.white30 : Colors.black26)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Container(
            key: ValueKey('bar_$_selectedChartTerm'),
            padding: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: chartMarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 36, color: SAMSColors.secondary.withOpacity(0.35)),
                        const SizedBox(height: 8),
                        Text(
                          'No marks recorded for ${_termNameChart(_selectedChartTerm ?? 1)}.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < chartMarks.length) {
                                final sub = chartMarks[idx].subject;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    sub.length > 3 ? sub.substring(0, 3) : sub,
                                    style: TextStyle(
                                      fontFamily: 'Inter', fontSize: 9,
                                      color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: chartMarks.asMap().entries.map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.percentage,
                            gradient: LinearGradient(
                              colors: [
                                widget.markColor(e.value.percentage),
                                widget.markColor(e.value.percentage).withOpacity(0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ],
                      )).toList(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) {
                            final m = chartMarks[group.x];
                            return BarTooltipItem(
                              '${m.subject}\n${m.marks.toInt()}/${m.maxMarks.toInt()} (${m.percentage.toStringAsFixed(1)}%)',
                              const TextStyle(fontFamily: 'Inter', fontSize: 11,
                                color: Colors.white, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsTab extends StatefulWidget {
  final List<TermMark> marks;
  final bool isDark;
  final Color Function(double) markColor;
  final String Function(double) grade;

  const _SubjectsTab({
    required this.marks,
    required this.isDark,
    required this.markColor,
    required this.grade,
  });

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab> {
  int? _filterTerm; // null = all terms average

  @override
  void initState() {
    super.initState();
    final terms = widget.marks.map((m) => m.term).toSet().toList()..sort();
    _filterTerm = terms.isNotEmpty ? terms.last : null;
  }

  @override
  void didUpdateWidget(_SubjectsTab old) {
    super.didUpdateWidget(old);
    if (old.marks != widget.marks) {
      final terms = widget.marks.map((m) => m.term).toSet().toList()..sort();
      if (_filterTerm != null && !terms.contains(_filterTerm)) {
        _filterTerm = terms.isNotEmpty ? terms.last : null;
      }
    }
  }

  String _termLabel(int t) {
    if (t == 1) return SAMSStrings.term1;
    if (t == 2) return SAMSStrings.term2;
    if (t == 3) return SAMSStrings.term3;
    return 'Term $t';
  }

  double _avg(String subject) {
    final filtered = _filterTerm != null
        ? widget.marks.where((m) => m.subject == subject && m.term == _filterTerm).toList()
        : widget.marks.where((m) => m.subject == subject).toList();
    if (filtered.isEmpty) return 0.0;
    return filtered.fold(0.0, (s, m) => s + m.percentage) / filtered.length;
  }

  @override
  Widget build(BuildContext context) {
    final allTerms = widget.marks.map((m) => m.term).toSet().toList()..sort();
    final availableTerms = ({1, 2, 3, ...allTerms}).toList()..sort();

    final activeMarks = _filterTerm != null
        ? widget.marks.where((m) => m.term == _filterTerm).toList()
        : widget.marks;
    final subjects = activeMarks.map((m) => m.subject).toSet().toList()
      ..sort((a, b) => _avg(b).compareTo(_avg(a)));

    return Column(
      children: [
        // ── Term filter strip ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
            border: Border(
              bottom: BorderSide(
                color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.06),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(SAMSStrings.allTerms, null, null),
                const SizedBox(width: 8),
                ...availableTerms.map((t) {
                  final tMarks = widget.marks.where((m) => m.term == t).toList();
                  final hasData = tMarks.isNotEmpty;
                  final tAvg = hasData
                      ? tMarks.fold(0.0, (s, m) => s + m.percentage) / tMarks.length
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChip(
                      _termLabel(t), t,
                      tAvg != null ? '${tAvg.toStringAsFixed(0)}%' : null,
                      hasData: hasData,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ── Subject list ──────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: subjects.isEmpty
                ? Center(
                    key: ValueKey('empty_${_filterTerm}'),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 44,
                              color: SAMSColors.secondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _filterTerm != null
                                ? 'No marks for ${_termLabel(_filterTerm!)} yet.'
                                : SAMSStrings.noMarksForTerm,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14,
                              color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    key: ValueKey('list_${_filterTerm}'),
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final subject = subjects[i];
                      final avg = _avg(subject);
                      final color = widget.markColor(avg);
                      final g = widget.grade(avg);
                      final subjectMarks = widget.marks
                          .where((m) => m.subject == subject).toList()
                        ..sort((a, b) => a.term.compareTo(b.term));

                      return TweenAnimationBuilder<double>(
                        key: ValueKey('${subject}_${_filterTerm}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 340 + i * 40),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                              offset: Offset(0, 12 * (1 - v)), child: child),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: widget.isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(widget.isDark ? 0.15 : 0.03),
                                blurRadius: 6, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(g,
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                                            fontWeight: FontWeight.w800, color: color)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(subject,
                                          style: const TextStyle(fontFamily: 'Poppins',
                                              fontSize: 13, fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 5),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: (avg / 100).clamp(0.0, 1.0)),
                                          duration: Duration(milliseconds: 580 + i * 50),
                                          curve: Curves.easeOutCubic,
                                          builder: (_, v, __) => LinearProgressIndicator(
                                            value: v,
                                            backgroundColor: color.withOpacity(0.15),
                                            valueColor: AlwaysStoppedAnimation(color),
                                            minHeight: 5,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${avg.toStringAsFixed(1)}%',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                                            fontWeight: FontWeight.w800, color: color)),
                                      if (_filterTerm == null)
                                        Text('Avg',
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                                            color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub)),
                                    ],
                                  ),
                                ],
                              ),
                              // Per-term mini badges in All-Terms mode
                              if (_filterTerm == null && subjectMarks.length > 1) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: subjectMarks.map((sm) {
                                    final tc = widget.markColor(sm.percentage);
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 5),
                                        decoration: BoxDecoration(
                                          color: tc.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(_termLabel(sm.term).replaceAll('Term ', 'T'),
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 9,
                                                color: widget.isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub)),
                                            const SizedBox(height: 2),
                                            Text('${sm.percentage.toStringAsFixed(0)}%',
                                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                                  fontWeight: FontWeight.w700, color: tc)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int? term, String? badge, {bool hasData = true}) {
    final isDark = widget.isDark;
    final isSelected = _filterTerm == term;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _filterTerm = term); },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? SAMSColors.secondary : (isDark ? SAMSColors.bgDarkSurface : SAMSColors.bgLightSurface),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? SAMSColors.secondary
                  : (hasData ? (isDark ? Colors.white24 : Colors.black12)
                              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
              width: 1.2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: SAMSColors.secondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white
                      : (hasData ? (isDark ? Colors.white70 : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.black38)),
                )),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.25) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : SAMSColors.secondary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Report Card Bottom Sheet ─────────────────────────────────────────────────

class _ReportCardSheet extends StatefulWidget {
  final List<TermMark> marks;
  final List<int> terms;
  final bool isDark;
  final Color Function(double) markColor;
  final String Function(double) grade;

  const _ReportCardSheet({
    required this.marks, required this.terms, required this.isDark,
    required this.markColor, required this.grade,
  });

  @override
  State<_ReportCardSheet> createState() => _ReportCardSheetState();
}

class _ReportCardSheetState extends State<_ReportCardSheet> {
  late int _term;

  @override
  void initState() {
    super.initState();
    _term = widget.terms.isNotEmpty ? widget.terms.last : 1;
  }

  String _tl(int t) {
    if (t == 1) return SAMSStrings.term1;
    if (t == 2) return SAMSStrings.term2;
    if (t == 3) return SAMSStrings.term3;
    return 'Term $t';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final termMarks = widget.marks.where((m) => m.term == _term).toList()
      ..sort((a, b) => a.subject.compareTo(b.subject));
    final totalScore = termMarks.fold(0.0, (s, m) => s + m.marks);
    final totalMax = termMarks.fold(0.0, (s, m) => s + m.maxMarks);
    final avg = totalMax > 0 ? (totalScore / totalMax * 100) : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Report Card',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(_tl(_term),
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: widget.terms.map((t) {
                            final isSel = _term == t;
                            return GestureDetector(
                              onTap: () { HapticFeedback.selectionClick(); setState(() => _term = t); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSel ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('T$t',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? SAMSColors.secondary : Colors.white70)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RStat('Score', '${totalScore.toInt()}/${totalMax.toInt()}'),
                      const SizedBox(width: 18),
                      _RStat('Average', '${avg.toStringAsFixed(1)}%'),
                      const SizedBox(width: 18),
                      _RStat('Subjects', '${termMarks.length}'),
                      const SizedBox(width: 18),
                      _RStat('Grade', widget.grade(avg)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: termMarks.isEmpty
                  ? Center(
                      child: Text(SAMSStrings.noMarksForTerm,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                          color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub)))
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: SAMSColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Expanded(flex: 3, child: Text('Subject',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700))),
                              SizedBox(width: 60, child: Text('Marks', textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
                                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub))),
                              SizedBox(width: 52, child: Text('%', textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
                                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub))),
                              const SizedBox(width: 36, child: Text('Grd', textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...termMarks.map((m) {
                          final pct = m.percentage;
                          final c = widget.markColor(pct);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(m.subject,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis)),
                                SizedBox(width: 60, child: Text('${m.marks.toInt()}/${m.maxMarks.toInt()}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub))),
                                SizedBox(width: 52, child: Text('${pct.toStringAsFixed(1)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                      fontWeight: FontWeight.w700, color: c))),
                                SizedBox(width: 36, child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(widget.grade(pct),
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                          fontWeight: FontWeight.w800, color: c)),
                                  ),
                                )),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Expanded(flex: 3, child: Text('Total',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                    fontWeight: FontWeight.w800, color: Colors.white))),
                              SizedBox(width: 60, child: Text('${totalScore.toInt()}/${totalMax.toInt()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                    fontWeight: FontWeight.w700, color: Colors.white))),
                              SizedBox(width: 52, child: Text('${avg.toStringAsFixed(1)}%',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                    fontWeight: FontWeight.w700, color: Colors.white))),
                              SizedBox(width: 36, child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(widget.grade(avg),
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                                        fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RStat extends StatelessWidget {
  final String label, value;
  const _RStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.white60)),
      Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
          fontWeight: FontWeight.w800, color: Colors.white)),
    ],
  );
}
