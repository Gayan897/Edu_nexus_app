import '../models/models.dart';

// ─── Early Warning System Service ─────────────────────────────────────────────
class EwsService {
  static List<EwsAlert> generateAlerts({
    required List<AttendanceRecord> attendance,
    required List<TermMark> marks,
    required String studentName,
  }) {
    final alerts = <EwsAlert>[];

    // 1. Attendance check
    if (attendance.isNotEmpty) {
      final presentCount = attendance.where((a) => a.status == AttendanceStatus.present).length;
      final attendanceRate = presentCount / attendance.length;

      if (attendanceRate < 0.75) {
        alerts.add(EwsAlert(
          type: 'attendance',
          severity: 'high',
          messageEn: '$studentName\'s attendance has dropped to ${(attendanceRate * 100).toStringAsFixed(0)}% this month. Regular attendance this week will help catch up on critical O/L subjects.',
          messageSi: '$studentName ගේ පැමිණීම මෙම මාසයේ ${(attendanceRate * 100).toStringAsFixed(0)}% දක්වා පහත වැටී ඇත. O/L විෂයයන් සඳහා නිතිපතා පැමිණීම මෙම සතියේ සිදු කරන්න.',
          messageTa: '$studentName-ன் வருகை இம்மாதம் ${(attendanceRate * 100).toStringAsFixed(0)}%-ஆக குறைந்துள்ளது. O/L பாடங்களை பிடிக்க இந்த வாரம் தொடர்ந்து வருகை தாருங்கள்.',
          value: attendanceRate * 100,
        ));
      } else if (attendanceRate < 0.85) {
        alerts.add(EwsAlert(
          type: 'attendance',
          severity: 'medium',
          messageEn: '$studentName\'s attendance is ${(attendanceRate * 100).toStringAsFixed(0)}%. A little more consistency will keep academic performance on track.',
          messageSi: '$studentName ගේ පැමිණීම ${(attendanceRate * 100).toStringAsFixed(0)}% කි. ස්ථිරව පැමිණීම ශිෂ්‍ය ක්‍රියාකාරිත්වය ඉහළ නංවනු ඇත.',
          messageTa: '$studentName-ன் வருகை ${(attendanceRate * 100).toStringAsFixed(0)}%-ஆக உள்ளது. சற்று நிலையாக வருகை தாருங்கள்.',
          value: attendanceRate * 100,
        ));
      }
    }

    // 2. Check marks by subject
    final latestTerms = <String, TermMark>{};
    for (final mark in marks) {
      if (!latestTerms.containsKey(mark.subject) || mark.term > latestTerms[mark.subject]!.term) {
        latestTerms[mark.subject] = mark;
      }
    }

    for (final entry in latestTerms.entries) {
      final pct = entry.value.percentage;
      if (pct < 50) {
        alerts.add(EwsAlert(
          type: 'marks',
          severity: 'high',
          subject: entry.key,
          messageEn: '$studentName scored ${pct.toStringAsFixed(0)}% in ${entry.key} (Term ${entry.value.term}). Extra attention and revision are strongly recommended.',
          messageSi: '$studentName ${entry.key} විෂයයේ ${pct.toStringAsFixed(0)}% ලකුණු ලබා ගෙන ඇත (${entry.value.term} කාලසීමාව). අමතර අවධානය අවශ්‍ය වේ.',
          messageTa: '$studentName ${entry.key} பாடத்தில் ${pct.toStringAsFixed(0)}% மதிப்பெண் பெற்றுள்ளார் (காலம் ${entry.value.term}). கூடுதல் கவனம் தேவை.',
          value: pct,
        ));
      } else if (pct < 65) {
        alerts.add(EwsAlert(
          type: 'marks',
          severity: 'medium',
          subject: entry.key,
          messageEn: '${entry.key} marks are at ${pct.toStringAsFixed(0)}%. Regular revision of Term ${entry.value.term} topics will help improve.',
          messageSi: '${entry.key} ලකුණු ${pct.toStringAsFixed(0)}% කි. ${entry.value.term} කාලසීමා මාතෘකා නිතිපතා නැවත සලකා බැලීම ප්‍රයෝජනවත් වනු ඇත.',
          messageTa: '${entry.key} மதிப்பெண் ${pct.toStringAsFixed(0)}%-ஆக உள்ளது. ${entry.value.term}-ம் காலத்தின் தலைப்புகளை தொடர்ந்து திருத்தி பாருங்கள்.',
          value: pct,
        ));
      }
    }

    // 3. Positive alerts
    if (alerts.isEmpty) {
      alerts.add(EwsAlert(
        type: 'positive',
        severity: 'low',
        messageEn: '🎉 $studentName is doing great! Attendance and academic performance are both on track. Keep up the excellent work!',
        messageSi: '🎉 $studentName ඉතා හොඳින් කාර්ය කරගෙන යයි! පැමිණීම සහ ශිෂ්‍ය ක්‍රියාකාරිත්වය යන දෙකම නිවැරදිව ඇත. දිගටම හොඳ වැඩ කරන්න!',
        messageTa: '🎉 $studentName மிகவும் சிறப்பாக செயல்படுகிறார்! வருகை மற்றும் கல்வி செயல்திறன் இரண்டும் சரியாக உள்ளன. சிறப்பான வேலையை தொடருங்கள்!',
      ));
    } else {
      // Add encouraging note even with warnings
      alerts.add(const EwsAlert(
        type: 'positive',
        severity: 'low',
        messageEn: '💪 Remember: every challenge is an opportunity to grow. You have the support of your teachers and family!',
        messageSi: '💪 මතක රාඛා: සෑම අභියෝගයක්ම වර්ධනය වීමේ අවස්ථාවකි. ඔබට ගුරුවරුන්ගේ සහ පවුලේ සහාය ඇත!',
        messageTa: '💪 நினைவில் கொள்: ஒவ்வொரு சவாலும் வளர்வதற்கான வாய்ப்பு. உங்கள் ஆசிரியர்களும் குடும்பமும் உங்களுக்கு ஆதரவாக உள்ளனர்!',
      ));
    }

    return alerts;
  }

  // A/L Stream Eligibility Predictor
  static List<StreamEligibility> predictStreams(List<TermMark> marks) {
    if (marks.isEmpty) return [];

    // Calculate average marks per subject
    final subjectAvgs = <String, double>{};
    final subjectCounts = <String, int>{};
    for (final mark in marks) {
      subjectAvgs[mark.subject] = (subjectAvgs[mark.subject] ?? 0) + mark.percentage;
      subjectCounts[mark.subject] = (subjectCounts[mark.subject] ?? 0) + 1;
    }
    for (final key in subjectAvgs.keys) {
      subjectAvgs[key] = subjectAvgs[key]! / (subjectCounts[key] ?? 1);
    }

    final mathAvg = subjectAvgs['Mathematics'] ?? subjectAvgs['Maths'] ?? 0;
    final sciAvg = subjectAvgs['Science'] ?? 0;
    final engAvg = subjectAvgs['English'] ?? 0;
    final histAvg = subjectAvgs['History'] ?? 0;
    final ictAvg = subjectAvgs['ICT'] ?? 0;
    final overall = subjectAvgs.values.fold(0.0, (a, b) => a + b) / (subjectAvgs.isEmpty ? 1 : subjectAvgs.length);

    String status(double score) {
      if (score >= 70) return 'eligible';
      if (score >= 55) return 'borderline';
      return 'not_eligible';
    }

    // Bio Science: requires strong Science + overall
    final bioScore = (sciAvg * 0.5 + overall * 0.3 + engAvg * 0.2).clamp(0, 100).toDouble();
    // Maths/Physical Science: requires strong Math + Science
    final mathScore = (mathAvg * 0.5 + sciAvg * 0.3 + ictAvg * 0.2).clamp(0, 100).toDouble();
    // Commerce: moderate marks + English
    final commerceScore = (overall * 0.5 + engAvg * 0.3 + (100 - mathAvg) * 0.05 + 50).clamp(0, 100).toDouble();
    // Technology: ICT + Math
    final techScore = (ictAvg * 0.5 + mathAvg * 0.3 + sciAvg * 0.2).clamp(0, 100).toDouble();
    // Arts: History + English + overall
    final artsScore = (histAvg * 0.4 + engAvg * 0.3 + overall * 0.3).clamp(0, 100).toDouble();

    return [
      StreamEligibility(
        stream: AlStream.bioScience,
        status: status(bioScore),
        score: bioScore,
        messageEn: 'Bio Science requires strong Science & overall performance. Eligibility: ${bioScore.toStringAsFixed(0)}%.',
        messageSi: 'ජෛව විද්‍යා ධාරාව ශක්තිමත් විද්‍යා සහ සාමාන්‍ය ක්‍රියාකාරිත්වය අවශ්‍ය කරයි. සුදුසුකම: ${bioScore.toStringAsFixed(0)}%.',
        messageTa: 'உயிரியல் அறிவியல் ஸ்ட்ரீமுக்கு வலுவான அறிவியல் மற்றும் ஒட்டுமொத்த செயல்திறன் தேவை. தகுதி: ${bioScore.toStringAsFixed(0)}%.',
      ),
      StreamEligibility(
        stream: AlStream.mathsScience,
        status: status(mathScore),
        score: mathScore,
        messageEn: 'Physical Science (Maths) needs strong Maths & Science. Eligibility: ${mathScore.toStringAsFixed(0)}%.',
        messageSi: 'භෞතික විද්‍යා (ගණිත) ධාරාව ශක්තිමත් ගණිත සහ විද්‍යාව අවශ්‍ය කරයි. සුදුසුකම: ${mathScore.toStringAsFixed(0)}%.',
        messageTa: 'இயற்பியல் அறிவியல் (கணிதம்) ஸ்ட்ரீமுக்கு வலுவான கணிதம் & அறிவியல் தேவை. தகுதி: ${mathScore.toStringAsFixed(0)}%.',
      ),
      StreamEligibility(
        stream: AlStream.commerce,
        status: status(commerceScore > 100 ? 100 : commerceScore),
        score: commerceScore > 100 ? 100 : commerceScore,
        messageEn: 'Commerce stream is accessible with moderate overall performance. Eligibility: ${(commerceScore > 100 ? 100 : commerceScore).toStringAsFixed(0)}%.',
        messageSi: 'වාණිජ ධාරාව මධ්‍යස්ථ සාමාන්‍ය ක්‍රියාකාරිත්වයෙන් ප්‍රවේශ විය හැකිය. සුදුසුකම: ${(commerceScore > 100 ? 100 : commerceScore).toStringAsFixed(0)}%.',
        messageTa: 'வணிகவியல் ஸ்ட்ரீம் மிதமான ஒட்டுமொத்த செயல்திறனுடன் அணுகலாம். தகுதி: ${(commerceScore > 100 ? 100 : commerceScore).toStringAsFixed(0)}%.',
      ),
      StreamEligibility(
        stream: AlStream.technology,
        status: status(techScore),
        score: techScore,
        messageEn: 'Technology stream suits ICT & Maths strengths. Eligibility: ${techScore.toStringAsFixed(0)}%.',
        messageSi: 'තාක්ෂණ ධාරාව ICT සහ ගණිත ශක්තියට ගැලපේ. සුදුසුකම: ${techScore.toStringAsFixed(0)}%.',
        messageTa: 'தொழில்நுட்ப ஸ்ட்ரீம் ICT மற்றும் கணித பலத்திற்கு ஏற்றது. தகுதி: ${techScore.toStringAsFixed(0)}%.',
      ),
      StreamEligibility(
        stream: AlStream.arts,
        status: status(artsScore),
        score: artsScore,
        messageEn: 'Arts stream values History, languages & humanities. Eligibility: ${artsScore.toStringAsFixed(0)}%.',
        messageSi: 'කලා ධාරාව ඉතිහාසය, භාෂා සහ මානවශාස්ත්‍ර අගය කරයි. සුදුසුකම: ${artsScore.toStringAsFixed(0)}%.',
        messageTa: 'கலை ஸ்ட்ரீம் வரலாறு, மொழிகள் மற்றும் மானிடவியலை மதிக்கிறது. தகுதி: ${artsScore.toStringAsFixed(0)}%.',
      ),
    ];
  }
}
