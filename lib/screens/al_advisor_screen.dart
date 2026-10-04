import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../services/ews_service.dart';
import '../models/models.dart';
import '../i18n/strings.dart';

class AlAdvisorScreen extends StatefulWidget {
  const AlAdvisorScreen({super.key});

  @override
  State<AlAdvisorScreen> createState() => _AlAdvisorScreenState();
}

class _AlAdvisorScreenState extends State<AlAdvisorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Adjustable O/L marks for prediction
  final _markControllers = <String, TextEditingController>{};
  late Map<String, double> _customMarks;
  List<StreamEligibility> _predictions = [];

  static const _olSubjects = [
    'Mathematics', 'Science', 'English', 'Sinhala', 'History', 'ICT',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    // Init with student's marks from provider (avg across terms) or defaults
    _customMarks = {};
    final provider = context.read<AppProvider>();
    final marks = provider.marks;
    for (final s in _olSubjects) {
      final subjectMarks = marks.where((m) => m.subject == s).toList();
      _customMarks[s] = subjectMarks.isNotEmpty
          ? subjectMarks.fold(0.0, (sum, m) => sum + m.marks) / subjectMarks.length
          : 60.0;
      _markControllers[s] = TextEditingController(
        text: _customMarks[s]!.toStringAsFixed(0),
      );
    }
    _recalculate();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in _markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalculate() {
    final termMarks = _customMarks.entries.map((e) => TermMark(
      studentId: 'kasun_student_001',
      subject: e.key,
      term: 3,
      marks: e.value,
      maxMarks: 100,
    )).toList();
    setState(() {
      _predictions = EwsService.predictStreams(termMarks);
    });
  }

  Color _streamColor(AlStream stream) {
    switch (stream) {
      case AlStream.bioScience: return const Color(0xFF059669);
      case AlStream.mathsScience: return SAMSColors.primary;
      case AlStream.commerce: return const Color(0xFFD97706);
      case AlStream.technology: return const Color(0xFF0891B2);
      case AlStream.arts: return const Color(0xFFDB2777);
    }
  }

  String _streamName(AlStream stream, AppLanguage lang) {
    if (lang == AppLanguage.sinhala) {
      switch (stream) {
        case AlStream.bioScience: return SAMSStrings.bioScience;
        case AlStream.mathsScience: return SAMSStrings.mathsStream;
        case AlStream.commerce: return SAMSStrings.commerceStream;
        case AlStream.technology: return SAMSStrings.technologyStream;
        case AlStream.arts: return SAMSStrings.artsStream;
      }
    } else if (lang == AppLanguage.tamil) {
      switch (stream) {
        case AlStream.bioScience: return SAMSStrings.bioScience;
        case AlStream.mathsScience: return SAMSStrings.mathsStream;
        case AlStream.commerce: return SAMSStrings.commerceStream;
        case AlStream.technology: return SAMSStrings.technologyStream;
        case AlStream.arts: return SAMSStrings.artsStream;
      }
    }
    switch (stream) {
      case AlStream.bioScience: return 'Bio Science';
      case AlStream.mathsScience: return 'Physical Science (Maths)';
      case AlStream.commerce: return 'Commerce';
      case AlStream.technology: return 'Technology';
      case AlStream.arts: return 'Arts';
    }
  }

  String _statusMessage(String status, AppLanguage lang) {
    if (lang == AppLanguage.sinhala) {
      switch (status) {
        case 'eligible': return '✅ ${SAMSStrings.eligible}';
        case 'borderline': return '⚠️ ${SAMSStrings.borderline}';
        default: return '❌ ${SAMSStrings.notEligible}';
      }
    } else if (lang == AppLanguage.tamil) {
      switch (status) {
        case 'eligible': return '✅ ${SAMSStrings.eligible}';
        case 'borderline': return '⚠️ ${SAMSStrings.borderline}';
        default: return '❌ ${SAMSStrings.notEligible}';
      }
    }
    switch (status) {
      case 'eligible': return '✅ Eligible';
      case 'borderline': return '⚠️ Borderline';
      default: return '❌ Not Eligible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final lang = provider.language;

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      appBar: AppBar(
        title: Text(SAMSStrings.alAdvisor),
        backgroundColor: SAMSColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins', fontSize: 16,
          fontWeight: FontWeight.w700, color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: SAMSStrings.streamPredictor),
            const Tab(text: 'University Pathways'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Stream Predictor Tab ──────────────────────────────────────────
          _StreamPredictorTab(
            olSubjects: _olSubjects,
            customMarks: _customMarks,
            markControllers: _markControllers,
            predictions: _predictions,
            isDark: isDark,
            lang: lang,
            streamColor: _streamColor,
            streamName: _streamName,
            statusMessage: _statusMessage,
            onMarkChanged: (subject, value) {
              _customMarks[subject] = value;
              _recalculate();
            },
          ),

          // ── University Pathways Tab ───────────────────────────────────────
          _UniversityPathwaysTab(
            isDark: isDark,
            lang: lang,
            streamColor: _streamColor,
            streamName: _streamName,
          ),
        ],
      ),
    );
  }
}

class _StreamPredictorTab extends StatelessWidget {
  final List<String> olSubjects;
  final Map<String, double> customMarks;
  final Map<String, TextEditingController> markControllers;
  final List<StreamEligibility> predictions;
  final bool isDark;
  final AppLanguage lang;
  final Color Function(AlStream) streamColor;
  final String Function(AlStream, AppLanguage) streamName;
  final String Function(String, AppLanguage) statusMessage;
  final void Function(String, double) onMarkChanged;

  const _StreamPredictorTab({
    required this.olSubjects, required this.customMarks,
    required this.markControllers, required this.predictions,
    required this.isDark, required this.lang,
    required this.streamColor, required this.streamName,
    required this.statusMessage, required this.onMarkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SAMSColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SAMSColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: SAMSColors.primaryLight, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adjust your O/L marks below to see which A/L streams you qualify for. These are predictions based on Sri Lanka\'s General A/L stream requirements.',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12, height: 1.5,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mark sliders
          const Text(
            'Adjust O/L Subject Marks',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...olSubjects.map((subject) {
            final mark = customMarks[subject] ?? 60;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(subject, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (mark >= 75 ? SAMSColors.present : mark >= 55 ? SAMSColors.late : SAMSColors.absent).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${mark.toStringAsFixed(0)}/100',
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: mark >= 75 ? SAMSColors.present : mark >= 55 ? SAMSColors.late : SAMSColors.absent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: SAMSColors.primary,
                      inactiveTrackColor: SAMSColors.primary.withOpacity(0.2),
                      thumbColor: SAMSColors.primary,
                      overlayColor: SAMSColors.primary.withOpacity(0.12),
                    ),
                    child: Slider(
                      value: mark,
                      min: 0, max: 100,
                      divisions: 100,
                      onChanged: (v) => onMarkChanged(subject, v),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Predictions
          Text(
            SAMSStrings.streamPredictor,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...predictions.map((pred) {
            final color = streamColor(pred.stream);
            final statusColor = pred.status == 'eligible'
                ? SAMSColors.present
                : pred.status == 'borderline'
                    ? SAMSColors.late
                    : SAMSColors.absent;

            final message = lang == AppLanguage.sinhala
                ? pred.messageSi
                : lang == AppLanguage.tamil
                    ? pred.messageTa
                    : pred.messageEn;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        streamName(pred.stream, lang),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusMessage(pred.status, lang),
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: pred.score / 100,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, height: 1.4,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UniversityPathwaysTab extends StatelessWidget {
  final bool isDark;
  final AppLanguage lang;
  final Color Function(AlStream) streamColor;
  final String Function(AlStream, AppLanguage) streamName;

  const _UniversityPathwaysTab({
    required this.isDark, required this.lang,
    required this.streamColor, required this.streamName,
  });

  @override
  Widget build(BuildContext context) {
    const pathways = SLUniversityPathways.pathways;

    String faculty(UniversityPathway p) {
      if (lang == AppLanguage.sinhala) return p.facultySi;
      if (lang == AppLanguage.tamil) return p.facultyTa;
      return p.facultyEn;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: SAMSColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SAMSColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: SAMSColors.primaryLight, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sri Lanka State University Z-Score Admission Pathways.\nZ-Score ranges are approximate based on recent years.',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, height: 1.5,
                    color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pathways.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = pathways[i];
              final color = streamColor(p.requiredStream);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded, size: 18, color: Colors.white70),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.degree,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                p.university,
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 11,
                                  color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: '🎓 Stream',
                          value: streamName(p.requiredStream, lang),
                          color: color,
                        ),
                        _InfoChip(
                          label: '📊 Z-Score',
                          value: '${p.zScoreMin.toStringAsFixed(1)} – ${p.zScoreMax.toStringAsFixed(1)}',
                          color: SAMSColors.primaryLight,
                        ),
                        _InfoChip(
                          label: '🏛️ Faculty',
                          value: faculty(p),
                          color: SAMSColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: Colors.grey)),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
