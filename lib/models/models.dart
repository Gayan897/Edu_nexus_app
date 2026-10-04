// ─── SAMS Data Models ─────────────────────────────────────────────────────────

// All four roles from the shared Firestore `users` collection.
// teacher/principal are used by the web app; student/parent are used by mobile.
enum UserRole { student, parent, teacher, principal }
enum AttendanceStatus { present, absent, late, excused }
enum AlStream { bioScience, mathsScience, commerce, technology, arts }

// ─── User / Auth ─────────────────────────────────────────────────────────────
class SAMSUser {
  final String id;
  final String username;
  final String? password; // Optional — from Firestore, used for local check
  final String name;
  final UserRole role;
  final String? studentId;     // For parents - linked student
  final String? classRoom;     // e.g. "11A"
  final String? grade;         // e.g. "11"
  final String? parentContact;
  final String? school;
  final String? classTeacher;

  const SAMSUser({
    required this.id,
    required this.username,
    this.password,
    required this.name,
    required this.role,
    this.studentId,
    this.classRoom,
    this.grade,
    this.parentContact,
    this.school,
    this.classTeacher,
  });

  factory SAMSUser.fromMap(Map<String, dynamic> map) => SAMSUser(
    id: map['id'] ?? '',
    username: map['username'] ?? '',
    password: map['password'],
    name: map['name'] ?? '',
    role: _parseRole(map['role']),
    studentId: map['studentId'],
    classRoom: map['classRoom'],
    grade: map['grade'],
    parentContact: map['parentContact'] ?? map['phone'] ?? map['mobile'] ?? map['contact'] ?? map['contactNumber'],
    school: map['school'] ?? map['schoolName'],
    classTeacher: map['classTeacher'] ?? map['teacherName'],
  );

  static UserRole _parseRole(dynamic r) {
    switch (r) {
      case 'parent': return UserRole.parent;
      case 'teacher': return UserRole.teacher;
      case 'principal': return UserRole.principal;
      default: return UserRole.student;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'name': name,
    'role': role.name,
    'studentId': studentId,
    'classRoom': classRoom,
    'grade': grade,
    'parentContact': parentContact,
    'school': school,
    'classTeacher': classTeacher,
  };
}

// ─── Student Profile (from Firestore `students` collection) ───────────────────
class SAMSStudentProfile {
  final String id;
  final String? admissionNumber;
  final String name;
  final String classRoom; // e.g. "11A"
  final String grade;     // e.g. "11"
  final String parentContact;
  final String? school;
  final String? classTeacher;

  const SAMSStudentProfile({
    required this.id,
    this.admissionNumber,
    required this.name,
    required this.classRoom,
    required this.grade,
    required this.parentContact,
    this.school,
    this.classTeacher,
  });

  factory SAMSStudentProfile.fromMap(Map<String, dynamic> map) => SAMSStudentProfile(
    id: map['id']?.toString() ?? '',
    admissionNumber: (map['admissionNumber'] ?? map['admission'] ?? map['admNo'] ?? map['studentAdmission'])?.toString(),
    name: (map['name'] ?? map['studentName'] ?? '')?.toString() ?? '',
    classRoom: (map['classRoom'] ?? map['classroom'] ?? map['class'] ?? '')?.toString() ?? '',
    grade: map['grade']?.toString() ?? '',
    parentContact: (map['parentContact'] ?? map['parentPhone'] ?? map['phone'] ?? map['mobile'] ?? map['contact'] ?? map['contactNumber'] ?? map['guardianPhone'] ?? map['guardianContact'] ?? '')?.toString() ?? '',
    school: (map['school'] ?? map['schoolName'] ?? map['schoolCensusCode'])?.toString(),
    classTeacher: (map['classTeacher'] ?? map['teacherName'])?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'admissionNumber': admissionNumber,
    'name': name,
    'classRoom': classRoom,
    'grade': grade,
    'parentContact': parentContact,
    'school': school,
    'classTeacher': classTeacher,
  };
}

// ─── Attendance ─────────────────────────────────────────────────────────────
class AttendanceRecord {
  final String? id;
  final String studentId;
  final String date;  // yyyy-MM-dd
  final AttendanceStatus status;

  const AttendanceRecord({
    this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) => AttendanceRecord(
    id: map['id'],
    studentId: map['studentId'] ?? '',
    date: map['date'] ?? '',
    status: _parseStatus(map['status']),
  );

  static AttendanceStatus _parseStatus(dynamic s) {
    switch (s) {
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      case 'excused': return AttendanceStatus.excused;
      default: return AttendanceStatus.present;
    }
  }
}

// ─── Term Marks ─────────────────────────────────────────────────────────────
class TermMark {
  final String studentId;
  final String subject;
  final int term;           // 1, 2, or 3
  final double marks;
  final double maxMarks;
  final String? classRoom;

  const TermMark({
    required this.studentId,
    required this.subject,
    required this.term,
    required this.marks,
    required this.maxMarks,
    this.classRoom,
  });

  double get percentage => maxMarks > 0 ? (marks / maxMarks * 100) : 0;

  factory TermMark.fromMap(Map<String, dynamic> map) => TermMark(
    studentId: map['studentId'] ?? '',
    subject: map['subject'] ?? '',
    term: (map['term'] as num?)?.toInt() ?? 1,
    marks: (map['marks'] as num?)?.toDouble() ?? 0,
    maxMarks: (map['maxMarks'] as num?)?.toDouble() ?? 100,
    classRoom: map['classRoom'],
  );
}

// ─── Timetable ──────────────────────────────────────────────────────────────
class TimetableSlot {
  final String classRoom;
  final int dayOfWeek;    // 1=Mon...5=Fri
  final int period;       // 1-7
  final String subject;
  final String teacher;
  final String? substituteTeacher;
  final bool hasSubstitution;

  const TimetableSlot({
    required this.classRoom,
    required this.dayOfWeek,
    required this.period,
    required this.subject,
    required this.teacher,
    this.substituteTeacher,
    this.hasSubstitution = false,
  });

  factory TimetableSlot.fromMap(Map<String, dynamic> map) => TimetableSlot(
    classRoom: map['classRoom'] ?? '',
    dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
    period: (map['period'] as num?)?.toInt() ?? 1,
    subject: map['subject'] ?? '',
    teacher: map['teacher'] ?? '',
    substituteTeacher: map['substituteTeacher'],
    hasSubstitution: map['hasSubstitution'] == true,
  );
}

// ─── Notice / Circular ───────────────────────────────────────────────────────
// Supports both the web app's single-language schema (title/body)
// and the mobile app's multilingual schema (titleEn/titleSi/titleTa).
class CircularNotice {
  final String id;
  final String titleEn;
  final String titleSi;
  final String titleTa;
  final String bodyEn;
  final String bodySi;
  final String bodyTa;
  final String date;
  final String category;
  final String? targetGrade;    // null = all grades
  final String? targetStream;   // null = all streams
  final String? targetRole;     // 'all' | 'teacher' | 'principal' — from web app

  const CircularNotice({
    required this.id,
    required this.titleEn,
    required this.titleSi,
    required this.titleTa,
    required this.bodyEn,
    required this.bodySi,
    required this.bodyTa,
    required this.date,
    required this.category,
    this.targetGrade,
    this.targetStream,
    this.targetRole,
  });

  factory CircularNotice.fromMap(Map<String, dynamic> map) => CircularNotice(
    id: map['id'] ?? '',
    // Fallback: use single-language title/body from web app schema
    titleEn: map['titleEn'] ?? map['title'] ?? '',
    titleSi: map['titleSi'] ?? map['title'] ?? '',
    titleTa: map['titleTa'] ?? map['title'] ?? '',
    bodyEn: map['bodyEn'] ?? map['body'] ?? '',
    bodySi: map['bodySi'] ?? map['body'] ?? '',
    bodyTa: map['bodyTa'] ?? map['body'] ?? '',
    date: map['date'] ?? '',
    category: map['category'] ?? 'general',
    targetGrade: map['targetGrade'],
    targetStream: map['targetStream'],
    targetRole: map['targetRole'],
  );
}

// ─── Parent Notification ──────────────────────────────────────────────────
class ParentNotification {
  final String id;
  final String studentId;
  final String studentName;
  final String date;
  final AttendanceStatus status;
  final String title;
  final String message;
  final String timestamp;
  final bool read;
  final String? teacherName;
  final String type;
  final String priority;
  final String? parentContact;

  const ParentNotification({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
    this.teacherName,
    this.type = 'attendance',
    this.priority = 'normal',
    this.parentContact,
  });

  factory ParentNotification.fromMap(Map<String, dynamic> map) => ParentNotification(
    id: map['id'] ?? '',
    studentId: map['studentId'] ?? '',
    studentName: map['studentName'] ?? '',
    date: map['date'] ?? '',
    status: _parseStatus(map['status']),
    title: map['title'] ?? 'Attendance Update',
    message: map['message'] ?? '',
    timestamp: map['timestamp'] ?? '',
    read: map['read'] == true,
    teacherName: map['teacherName'],
    type: map['type'] ?? 'attendance',
    priority: map['priority'] ?? 'normal',
    parentContact: map['parentContact'],
  );

  static AttendanceStatus _parseStatus(dynamic s) {
    switch (s) {
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      case 'excused': return AttendanceStatus.excused;
      default: return AttendanceStatus.present;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'date': date,
    'status': status.name,
    'title': title,
    'message': message,
    'timestamp': timestamp,
    'read': read,
    'teacherName': teacherName,
    'type': type,
    'priority': priority,
    'parentContact': parentContact,
  };
}

// ─── EWS Alert ─────────────────────────────────────────────────────────────
class EwsAlert {
  final String type;      // 'attendance' | 'marks' | 'positive'
  final String severity;  // 'low' | 'medium' | 'high'
  final String messageEn;
  final String messageSi;
  final String messageTa;
  final String? subject;
  final double? value;

  const EwsAlert({
    required this.type,
    required this.severity,
    required this.messageEn,
    required this.messageSi,
    required this.messageTa,
    this.subject,
    this.value,
  });
}

// ─── A/L Stream Prediction ─────────────────────────────────────────────────
class StreamEligibility {
  final AlStream stream;
  final String status;    // 'eligible' | 'borderline' | 'not_eligible'
  final double score;     // 0-100 eligibility score
  final String messageEn;
  final String messageSi;
  final String messageTa;

  const StreamEligibility({
    required this.stream,
    required this.status,
    required this.score,
    required this.messageEn,
    required this.messageSi,
    required this.messageTa,
  });
}

class UniversityPathway {
  final String degree;
  final String university;
  final AlStream requiredStream;
  final double zScoreMin;
  final double zScoreMax;
  final String facultyEn;
  final String facultySi;
  final String facultyTa;

  const UniversityPathway({
    required this.degree,
    required this.university,
    required this.requiredStream,
    required this.zScoreMin,
    required this.zScoreMax,
    required this.facultyEn,
    required this.facultySi,
    required this.facultyTa,
  });
}

// ─── Sri Lanka UGC University Pathways Reference Data ───────────────────────
class SLUniversityPathways {
  static const List<UniversityPathway> pathways = [
    // ── Bio Science Stream ────────────────────────────────────────────
    UniversityPathway(
      degree: 'MBBS Medicine',
      university: 'University of Colombo',
      requiredStream: AlStream.bioScience,
      zScoreMin: 1.8, zScoreMax: 3.0,
      facultyEn: 'Faculty of Medicine',
      facultySi: 'වෛද්‍ය පීඨය',
      facultyTa: 'மருத்துவ பீடம்',
    ),
    UniversityPathway(
      degree: 'MBBS Medicine',
      university: 'University of Peradeniya',
      requiredStream: AlStream.bioScience,
      zScoreMin: 1.7, zScoreMax: 2.8,
      facultyEn: 'Faculty of Medicine',
      facultySi: 'වෛද්‍ය පීඨය',
      facultyTa: 'மருத்துவ பீடம்',
    ),
    UniversityPathway(
      degree: 'MBBS Medicine',
      university: 'University of Ruhuna',
      requiredStream: AlStream.bioScience,
      zScoreMin: 1.5, zScoreMax: 2.5,
      facultyEn: 'Faculty of Medicine',
      facultySi: 'වෛද්‍ය පීඨය',
      facultyTa: 'மருத்துவ பீடம்',
    ),
    UniversityPathway(
      degree: 'MBBS Medicine',
      university: 'Rajarata University of Sri Lanka',
      requiredStream: AlStream.bioScience,
      zScoreMin: 1.4, zScoreMax: 2.3,
      facultyEn: 'Faculty of Medicine & Allied Sciences',
      facultySi: 'වෛද්‍ය හා ආශ්‍රිත විද්‍යා පීඨය',
      facultyTa: 'மருத்துவம் மற்றும் தொடர்புடைய அறிவியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Nursing',
      university: 'University of Colombo',
      requiredStream: AlStream.bioScience,
      zScoreMin: 0.8, zScoreMax: 1.6,
      facultyEn: 'Faculty of Medicine',
      facultySi: 'වෛද්‍ය පීඨය',
      facultyTa: 'மருத்துவ பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Agriculture',
      university: 'University of Peradeniya',
      requiredStream: AlStream.bioScience,
      zScoreMin: 0.3, zScoreMax: 1.0,
      facultyEn: 'Faculty of Agriculture',
      facultySi: 'කෘෂිකර්ම පීඨය',
      facultyTa: 'விவசாயம் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Food Science & Technology',
      university: 'Wayamba University of Sri Lanka',
      requiredStream: AlStream.bioScience,
      zScoreMin: 0.2, zScoreMax: 0.8,
      facultyEn: 'Faculty of Livestock, Fisheries & Nutrition',
      facultySi: 'පශු, ධීවර සහ පෝෂණ පීඨය',
      facultyTa: 'கால்நடை, மீன்வளம் மற்றும் ஊட்டச்சத்து பீடம்',
    ),

    // ── Physical Science (Maths) Stream ───────────────────────────────
    UniversityPathway(
      degree: 'BSc Engineering',
      university: 'University of Moratuwa',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 1.6, zScoreMax: 2.5,
      facultyEn: 'Faculty of Engineering',
      facultySi: 'ඉංජිනේරු පීඨය',
      facultyTa: 'பொறியியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Engineering',
      university: 'University of Peradeniya',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 1.4, zScoreMax: 2.2,
      facultyEn: 'Faculty of Engineering',
      facultySi: 'ඉංජිනේරු පීඨය',
      facultyTa: 'பொறியியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Engineering',
      university: 'University of Ruhuna',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 1.2, zScoreMax: 2.0,
      facultyEn: 'Faculty of Engineering',
      facultySi: 'ඉංජිනේරු පීඨය',
      facultyTa: 'பொறியியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Computer Science',
      university: 'University of Colombo',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 1.0, zScoreMax: 1.8,
      facultyEn: 'Faculty of Science',
      facultySi: 'විද්‍යා පීඨය',
      facultyTa: 'அறிவியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Information Technology',
      university: 'University of Kelaniya',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 0.8, zScoreMax: 1.6,
      facultyEn: 'Faculty of Computing & Technology',
      facultySi: 'පරිගණක හා තාක්ෂණ පීඨය',
      facultyTa: 'கணினி மற்றும் தொழில்நுட்ப பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Physical Science',
      university: 'University of Sri Jayewardenepura',
      requiredStream: AlStream.mathsScience,
      zScoreMin: 0.6, zScoreMax: 1.4,
      facultyEn: 'Faculty of Applied Sciences',
      facultySi: 'ව්‍යවහාරික විද්‍යා පීඨය',
      facultyTa: 'பயன்பாட்டு அறிவியல் பீடம்',
    ),

    // ── Commerce Stream ───────────────────────────────────────────────
    UniversityPathway(
      degree: 'BBA Business Administration',
      university: 'University of Sri Jayewardenepura',
      requiredStream: AlStream.commerce,
      zScoreMin: 0.5, zScoreMax: 1.4,
      facultyEn: 'Faculty of Management Studies',
      facultySi: 'කළමනාකරණ අධ්‍යයන පීඨය',
      facultyTa: 'மேலாண்மை ஆய்வு பீடம்',
    ),
    UniversityPathway(
      degree: 'BCom Accountancy & Finance',
      university: 'University of Kelaniya',
      requiredStream: AlStream.commerce,
      zScoreMin: 0.4, zScoreMax: 1.2,
      facultyEn: 'Faculty of Commerce & Management',
      facultySi: 'වාණිජ හා කළමනාකරණ පීඨය',
      facultyTa: 'வணிகவியல் மற்றும் மேலாண்மை பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Economics',
      university: 'University of Colombo',
      requiredStream: AlStream.commerce,
      zScoreMin: 0.6, zScoreMax: 1.5,
      facultyEn: 'Faculty of Arts',
      facultySi: 'කලා පීඨය',
      facultyTa: 'கலை பீடம்',
    ),

    // ── Technology Stream ─────────────────────────────────────────────
    UniversityPathway(
      degree: 'BSc Technology (Engineering)',
      university: 'University of Vocational Technology (UNIVOTEC)',
      requiredStream: AlStream.technology,
      zScoreMin: 0.3, zScoreMax: 1.2,
      facultyEn: 'Faculty of Technology',
      facultySi: 'තාක්ෂණ පීඨය',
      facultyTa: 'தொழில்நுட்ப பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc Engineering Technology',
      university: 'Uva Wellassa University',
      requiredStream: AlStream.technology,
      zScoreMin: 0.2, zScoreMax: 1.0,
      facultyEn: 'Faculty of Science & Technology',
      facultySi: 'විද්‍යා හා තාක්ෂණ පීඨය',
      facultyTa: 'அறிவியல் மற்றும் தொழில்நுட்ப பீடம்',
    ),
    UniversityPathway(
      degree: 'BSc ICT',
      university: 'University of Moratuwa',
      requiredStream: AlStream.technology,
      zScoreMin: 0.8, zScoreMax: 1.5,
      facultyEn: 'Faculty of Information Technology',
      facultySi: 'තොරතුරු තාක්ෂණ පීඨය',
      facultyTa: 'தகவல் தொழில்நுட்ப பீடம்',
    ),

    // ── Arts Stream ───────────────────────────────────────────────────
    UniversityPathway(
      degree: 'BA Social Sciences',
      university: 'University of Kelaniya',
      requiredStream: AlStream.arts,
      zScoreMin: 0.1, zScoreMax: 0.8,
      facultyEn: 'Faculty of Social Sciences',
      facultySi: 'සමාජ විද්‍යා පීඨය',
      facultyTa: 'சமூக அறிவியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BA Mass Communication',
      university: 'University of Kelaniya',
      requiredStream: AlStream.arts,
      zScoreMin: 0.2, zScoreMax: 1.0,
      facultyEn: 'Faculty of Humanities',
      facultySi: 'මානවශාස්ත්‍ර පීඨය',
      facultyTa: 'மானிடவியல் பீடம்',
    ),
    UniversityPathway(
      degree: 'BA Law (LLB)',
      university: 'University of Colombo',
      requiredStream: AlStream.arts,
      zScoreMin: 0.8, zScoreMax: 1.8,
      facultyEn: 'Faculty of Law',
      facultySi: 'නීති පීඨය',
      facultyTa: 'சட்ட பீடம்',
    ),
    UniversityPathway(
      degree: 'BA Political Science',
      university: 'University of Peradeniya',
      requiredStream: AlStream.arts,
      zScoreMin: 0.1, zScoreMax: 0.7,
      facultyEn: 'Faculty of Arts',
      facultySi: 'කලා පීඨය',
      facultyTa: 'கலை பீடம்',
    ),
    UniversityPathway(
      degree: 'BA Eastern Languages',
      university: 'University of Jaffna',
      requiredStream: AlStream.arts,
      zScoreMin: 0.1, zScoreMax: 0.6,
      facultyEn: 'Faculty of Arts',
      facultySi: 'කලා පීඨය',
      facultyTa: 'கலை பீடம்',
    ),
  ];
}


// ─── University Pathways end ─────────────────────────────────────────────────
// (DemoData removed — app now reads live data from Firebase Firestore)
