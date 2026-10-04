// ─── SAMS Firestore Database Service ─────────────────────────────────────────
// Reads & writes to the same Firestore collections as the React web app.
// Collections: users, students, teachers, attendance, term_marks, timetable, notices

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users & Authentication ───────────────────────────────────────────────

  /// Fetch a user from Firestore by username.
  /// Supports all roles: student, parent, teacher, principal.
  Future<SAMSUser?> getUserByUsername(String username) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) return null;

    final lower = cleanUsername.toLowerCase();
    final digitsOnly = cleanUsername.replaceAll(RegExp(r'[^0-9]'), '');

    AppLogger.db('Querying user by username',
        collection: 'users', action: 'get', data: cleanUsername);
    try {
      // 1. Exact match by `username`
      final snap = await _db
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final user = SAMSUser.fromMap({'id': snap.docs.first.id, ...snap.docs.first.data()});
        AppLogger.auth('User retrieved successfully',
            username: user.username, role: user.role.name);
        return user;
      }

      // 2. Direct match by document ID in `users`
      final docSnap = await _db.collection('users').doc(cleanUsername).get();
      if (docSnap.exists && docSnap.data() != null) {
        final user = SAMSUser.fromMap({'id': docSnap.id, ...docSnap.data()!});
        AppLogger.auth('User retrieved by ID successfully',
            username: user.username, role: user.role.name);
        return user;
      }

      // 3. Case-insensitive scan across users collection (matches username, ID, admissionNumber, studentId)
      final allUsers = await _db.collection('users').get();
      for (final doc in allUsers.docs) {
        final data = doc.data();
        final user = SAMSUser.fromMap({'id': doc.id, ...data});
        final uName = user.username.trim().toLowerCase();
        final uId = user.id.trim().toLowerCase();
        final docId = doc.id.trim().toLowerCase();
        final sId = (user.studentId ?? '').trim().toLowerCase();
        final uAdm = (data['admissionNumber'] ?? data['admission'] ?? '').toString().trim().toLowerCase();

        if (uName == lower || uId == lower || docId == lower || sId == lower || uAdm == lower) {
          return user;
        }

        if (digitsOnly.length >= 4) {
          final uNameDigits = uName.replaceAll(RegExp(r'[^0-9]'), '');
          final uIdDigits = uId.replaceAll(RegExp(r'[^0-9]'), '');
          final docIdDigits = docId.replaceAll(RegExp(r'[^0-9]'), '');
          final sIdDigits = sId.replaceAll(RegExp(r'[^0-9]'), '');
          final uAdmDigits = uAdm.replaceAll(RegExp(r'[^0-9]'), '');
          if (uNameDigits == digitsOnly || uIdDigits == digitsOnly || docIdDigits == digitsOnly || sIdDigits == digitsOnly || uAdmDigits == digitsOnly) {
            return user;
          }
        }
      }

      // 4. Fallback: check if a student record exists in `students` collection that has credentials
      final studentSnap = await _db.collection('students').get();
      for (final doc in studentSnap.docs) {
        final data = doc.data();
        final sId = doc.id.trim().toLowerCase();
        final sAdm = (data['admissionNumber'] ?? data['admission'] ?? '').toString().trim().toLowerCase();
        final sUsername = (data['username'] ?? '').toString().trim().toLowerCase();
        final sPassword = (data['password'] ?? '').toString();

        if ((sId == lower || sAdm == lower || sUsername == lower) && sPassword.isNotEmpty) {
          return SAMSUser(
            id: doc.id,
            username: data['username'] ?? (sAdm.isNotEmpty ? sAdm : sId),
            password: sPassword,
            name: data['name'] ?? '',
            role: UserRole.student,
            classRoom: data['classRoom'] ?? data['classroom'],
            grade: data['grade']?.toString(),
            parentContact: data['parentContact'] ?? data['parentPhone'],
            school: data['school'] ?? data['schoolName'],
            classTeacher: data['classTeacher'],
          );
        }
      }

      AppLogger.auth('User not found in Firestore', username: cleanUsername);
      return null;
    } catch (e, st) {
      AppLogger.error('Failed to get user by username',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch a user by their document ID.
  Future<SAMSUser?> getUserById(String id) async {
    AppLogger.db('Fetching user by ID',
        collection: 'users', action: 'get', data: id);
    try {
      final doc = await _db.collection('users').doc(id).get();
      if (!doc.exists || doc.data() == null) {
        AppLogger.auth('User document does not exist for ID', data: id);
        return null;
      }
      return SAMSUser.fromMap(doc.data()!);
    } catch (e, st) {
      AppLogger.error('Failed to get user by ID',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Update password for a user in Firestore `users` collection.
  Future<void> updateUserPassword({
    required String username,
    required String newPassword,
  }) async {
    final cleanUsername = username.trim();
    AppLogger.db('Updating user password',
        collection: 'users', action: 'update', data: cleanUsername);
    try {
      final snap = await _db
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw Exception('User account not found.');
      }

      final docId = snap.docs.first.id;
      await _db.collection('users').doc(docId).update({
        'password': newPassword,
      });

      AppLogger.auth('Password updated successfully in Firestore', username: cleanUsername);
    } catch (e, st) {
      AppLogger.error('Failed to update user password in Firestore',
          tag: 'AUTH', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Resolve the registered phone number for a user (checks user doc and student profile).
  Future<String?> resolveUserPhoneNumber(SAMSUser user) async {
    if (user.parentContact != null && user.parentContact!.trim().isNotEmpty) {
      return user.parentContact!.trim();
    }

    // If student, check the student profile document
    if (user.role == UserRole.student) {
      try {
        final profile = await getStudentById(user.id);
        if (profile != null && profile.parentContact.trim().isNotEmpty) {
          return profile.parentContact.trim();
        }
      } catch (_) {}
    }

    // If parent, check linked student's profile
    if (user.role == UserRole.parent && user.studentId != null && user.studentId!.isNotEmpty) {
      try {
        final profile = await getStudentById(user.studentId!);
        if (profile != null && profile.parentContact.trim().isNotEmpty) {
          return profile.parentContact.trim();
        }
      } catch (_) {}
    }

    return null;
  }

  /// Create a new user document in Firestore `users` collection.
  Future<void> createUser(SAMSUser user) async {
    AppLogger.db('Creating user document',
        collection: 'users', action: 'set', data: user.username);
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
      AppLogger.auth('User created successfully in Firestore',
          username: user.username, role: user.role.name);
    } catch (e, st) {
      AppLogger.error('Failed to create user in Firestore',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Register a role-based user and populate associated role collections.
  Future<SAMSUser> registerUser({
    required String id,
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? grade,
    String? classRoom,
    String? parentContact,
    String? studentId,
    String? subject,
    String? school,
    String? classTeacher,
  }) async {
    AppLogger.auth('Initiating role-based user registration',
        username: username, role: role.name);

    // 1. Check if username is already taken
    final existing = await getUserByUsername(username);
    if (existing != null) {
      AppLogger.warning('Registration failed: Username already taken',
          tag: 'AUTH', error: username);
      throw Exception(
          'Username is already taken. Please choose another username.');
    }

    final user = SAMSUser(
      id: id,
      username: username.trim(),
      password: password,
      name: name.trim(),
      role: role,
      grade: grade,
      classRoom: classRoom,
      parentContact: parentContact,
      studentId: studentId,
      school: school,
      classTeacher: classTeacher,
    );

    // 2. Write to `users` collection
    await createUser(user);

    // 3. Write role-specific profile document
    if (role == UserRole.student) {
      final studentProfile = SAMSStudentProfile(
        id: id,
        name: name.trim(),
        classRoom: classRoom ?? '',
        grade: grade ?? '',
        parentContact: parentContact ?? '',
        school: school,
        classTeacher: classTeacher,
      );
      await createStudent(studentProfile);
    } else if (role == UserRole.teacher) {
      await createTeacherProfile(user, subject: subject, classRoom: classRoom);
    }

    AppLogger.auth('Registration completed successfully',
        username: username, role: role.name);
    return user;
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  /// Create or update student profile in Firestore `students` collection.
  Future<void> createStudent(SAMSStudentProfile student) async {
    AppLogger.db('Creating student profile document',
        collection: 'students', action: 'set', data: student.id);
    try {
      await _db.collection('students').doc(student.id).set(student.toMap(), SetOptions(merge: true));
      AppLogger.info('Student profile saved', tag: 'DB', data: student.name);
    } catch (e, st) {
      AppLogger.error('Failed to save student profile',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch a student record by their ID.
  Future<SAMSStudentProfile?> getStudentById(String studentId) async {
    final cleanId = studentId.trim();
    if (cleanId.isEmpty) return null;
    AppLogger.db('Fetching student profile',
        collection: 'students', action: 'get', data: cleanId);
    try {
      final doc = await _db.collection('students').doc(cleanId).get();
      if (!doc.exists || doc.data() == null) return null;
      return SAMSStudentProfile.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e, st) {
      AppLogger.error('Failed to get student profile',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Schools & Teachers ───────────────────────────────────────────────────

  /// Fetch real registered schools list from Firestore `schools` collection.
  Future<List<String>> getSchools() async {
    try {
      AppLogger.db('Fetching schools list from Firestore',
          collection: 'schools', action: 'get');
      final snap = await _db.collection('schools').get();
      if (snap.docs.isNotEmpty) {
        final List<String> schoolNames = [];
        for (final doc in snap.docs) {
          final data = doc.data();
          final name = data['name'] ?? data['schoolName'] ?? data['school'];
          if (name != null && name.toString().trim().isNotEmpty) {
            schoolNames.add(name.toString().trim());
          }
        }
        if (schoolNames.isNotEmpty) {
          final uniqueSchools = schoolNames.toSet().toList()..sort();
          return uniqueSchools;
        }
      }

      // Also check if any schools exist in `users` or `students` collections
      final usersSnap = await _db
          .collection('users')
          .where('school', isNull: false)
          .limit(50)
          .get();
      final List<String> userSchools = [];
      for (final doc in usersSnap.docs) {
        final sch = doc.data()['school']?.toString().trim();
        if (sch != null && sch.isNotEmpty) {
          userSchools.add(sch);
        }
      }
      if (userSchools.isNotEmpty) {
        final uniqueSchools = userSchools.toSet().toList()..sort();
        return uniqueSchools;
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch schools from Firestore',
          tag: 'DB', error: e.toString());
    }
    return [];
  }

  /// Suggest or lookup the designated real Class Teacher for a given class & school from Firestore.
  Future<String> getClassTeacherForClass(String classRoom, {String? school}) async {
    final cleanCls = classRoom.trim().toUpperCase();
    if (cleanCls.isEmpty) return '';

    try {
      // 1. Check Firestore `teachers` collection for a teacher assigned to this classroom
      final snap = await _db
          .collection('teachers')
          .where('classRoom', isEqualTo: cleanCls)
          .limit(5)
          .get();

      if (snap.docs.isNotEmpty) {
        if (school != null && school.trim().isNotEmpty) {
          for (final doc in snap.docs) {
            final data = doc.data();
            final docSchool = data['school'] ?? data['schoolName'];
            if (docSchool != null &&
                docSchool.toString().trim().toLowerCase() ==
                    school.trim().toLowerCase()) {
              final teacherName = data['name'];
              if (teacherName != null &&
                  teacherName.toString().trim().isNotEmpty) {
                return teacherName.toString().trim();
              }
            }
          }
        }
        final teacherName = snap.docs.first.data()['name'];
        if (teacherName != null && teacherName.toString().trim().isNotEmpty) {
          return teacherName.toString().trim();
        }
      }

      // 2. Check Firestore `users` collection for role=teacher with this classRoom
      final userSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('classRoom', isEqualTo: cleanCls)
          .limit(5)
          .get();

      if (userSnap.docs.isNotEmpty) {
        if (school != null && school.trim().isNotEmpty) {
          for (final doc in userSnap.docs) {
            final data = doc.data();
            final docSchool = data['school'] ?? data['schoolName'];
            if (docSchool != null &&
                docSchool.toString().trim().toLowerCase() ==
                    school.trim().toLowerCase()) {
              final teacherName = data['name'];
              if (teacherName != null &&
                  teacherName.toString().trim().isNotEmpty) {
                return teacherName.toString().trim();
              }
            }
          }
        }
        final teacherName = userSnap.docs.first.data()['name'];
        if (teacherName != null && teacherName.toString().trim().isNotEmpty) {
          return teacherName.toString().trim();
        }
      }
    } catch (e) {
      AppLogger.warning('Class teacher query lookup failed',
          tag: 'DB', error: e.toString());
    }

    // Return empty string when no real teacher record exists in Firestore
    return '';
  }

  /// Create teacher profile in Firestore `teachers` collection matching web schema.
  Future<void> createTeacherProfile(
    SAMSUser user, {
    String? subject,
    String? classRoom,
  }) async {
    AppLogger.db('Creating teacher profile document',
        collection: 'teachers', action: 'set', data: user.id);
    try {
      await _db.collection('teachers').doc(user.id).set({
        'id': user.id,
        'name': user.name,
        'subject': subject ?? 'Not assigned',
        'classRoom': classRoom ?? 'Not assigned',
        'casualBalance': 7,
        'medicalBalance': 14,
        'annualBalance': 21,
      });
      AppLogger.info('Teacher profile created in Firestore',
          tag: 'DB', data: user.name);
    } catch (e, st) {
      AppLogger.error('Failed to create teacher profile',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  /// Fetch all attendance records for a student.
  Future<List<AttendanceRecord>> getAttendanceForStudent(
      String studentId) async {
    AppLogger.db('Querying attendance records',
        collection: 'attendance', action: 'get', data: studentId);
    try {
      final snap = await _db
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      final list = snap.docs
          .map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      AppLogger.db('Attendance records retrieved: ${list.length}',
          collection: 'attendance');
      return list;
    } catch (e, st) {
      AppLogger.error('Failed to fetch attendance',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Term Marks ───────────────────────────────────────────────────────────

  /// Fetch all term marks for a student.
  Future<List<TermMark>> getTermMarksForStudent(String studentId) async {
    AppLogger.db('Querying term marks',
        collection: 'term_marks', action: 'get', data: studentId);
    try {
      final snap = await _db
          .collection('term_marks')
          .where('studentId', isEqualTo: studentId)
          .get();

      final list = snap.docs.map((d) => TermMark.fromMap(d.data())).toList();
      AppLogger.db('Term marks retrieved: ${list.length}',
          collection: 'term_marks');
      return list;
    } catch (e, st) {
      AppLogger.error('Failed to fetch term marks',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Real-time stream of term marks for a student.
  Stream<List<TermMark>> streamTermMarksForStudent(String studentId) {
    final cleanSid = studentId.trim();
    if (cleanSid.isEmpty) return const Stream.empty();
    return _db
        .collection('term_marks')
        .where('studentId', isEqualTo: cleanSid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TermMark.fromMap(d.data())).toList());
  }

  // ─── Timetable ────────────────────────────────────────────────────────────

  /// Fetch timetable slots for a classroom (e.g. "11A").
  Future<List<TimetableSlot>> getTimetableForClass(String classRoom) async {
    if (classRoom.isEmpty) return [];
    AppLogger.db('Querying timetable for class',
        collection: 'timetable', action: 'get', data: classRoom);
    try {
      final snap = await _db
          .collection('timetable')
          .where('classRoom', isEqualTo: classRoom)
          .get();

      final list =
          snap.docs.map((d) => TimetableSlot.fromMap(d.data())).toList()
            ..sort((a, b) {
              final dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
              return dayComp != 0 ? dayComp : a.period.compareTo(b.period);
            });

      AppLogger.db('Timetable slots retrieved: ${list.length}',
          collection: 'timetable');
      return list;
    } catch (e, st) {
      AppLogger.error('Failed to fetch timetable',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Notices / Circulars ──────────────────────────────────────────────────

  /// Fetch all notices visible to students/parents.
  /// Filters out teacher/principal-only notices.
  Future<List<CircularNotice>> getNoticesForStudents({
    String? targetGrade,
  }) async {
    AppLogger.db('Querying school notices',
        collection: 'notices', action: 'get', data: targetGrade);
    try {
      final snap = await _db.collection('notices').get();

      final notices = snap.docs
          .map((d) => CircularNotice.fromMap({...d.data(), 'id': d.id}))
          .where((n) {
        if (n.targetRole == 'teacher' || n.targetRole == 'principal') {
          return false;
        }
        if (targetGrade != null && targetGrade.isNotEmpty) {
          if (n.targetGrade != null && n.targetGrade != targetGrade) {
            return false;
          }
        }
        return true;
      }).toList();

      notices.sort((a, b) => b.date.compareTo(a.date));
      AppLogger.db('Notices retrieved: ${notices.length}',
          collection: 'notices');
      return notices;
    } catch (e, st) {
      AppLogger.error('Failed to fetch notices',
          tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Parent & Student Auto-Linking ────────────────────────────────────────

  /// Find student profile by student admission number / ID / username.
  Future<SAMSStudentProfile?> findStudentByAdmissionNumber(String admissionNumber) async {
    final rawInput = admissionNumber.trim();
    if (rawInput.isEmpty) return null;

    final clean = rawInput.toUpperCase();
    final digitsOnly = rawInput.replaceAll(RegExp(r'[^0-9]'), '');

    AppLogger.db('Looking up student by admission number',
        collection: 'students', data: clean);

    try {
      // 1. Direct match by document ID in `students` collection
      final direct = await getStudentById(rawInput);
      if (direct != null) return await _enrichStudentParentContact(direct);

      // 2. Query `students` collection by exact `admissionNumber`
      final admSnap = await _db
          .collection('students')
          .where('admissionNumber', isEqualTo: clean)
          .limit(1)
          .get();
      if (admSnap.docs.isNotEmpty) {
        final data = admSnap.docs.first.data();
        final s = SAMSStudentProfile.fromMap({'id': admSnap.docs.first.id, ...data});
        return await _enrichStudentParentContact(s);
      }

      // 3. Scan all docs in `students` collection for flexible match
      final snap = await _db.collection('students').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final s = SAMSStudentProfile.fromMap({'id': doc.id, ...data});

        final docId = doc.id.trim().toUpperCase();
        final sId = s.id.trim().toUpperCase();
        final sAdm = (s.admissionNumber ?? data['admission'] ?? data['admNo'] ?? data['studentAdmission'] ?? '').toString().trim().toUpperCase();
        final sName = s.name.trim().toUpperCase();

        // Exact match against ID, Admission Number, or Doc ID
        if (docId == clean || sId == clean || sAdm == clean || sName == clean) {
          return await _enrichStudentParentContact(s);
        }

        // Numeric digits match (e.g. 44424 matches ADM-44424)
        if (digitsOnly.length >= 4) {
          final sAdmDigits = sAdm.replaceAll(RegExp(r'[^0-9]'), '');
          final sIdDigits = sId.replaceAll(RegExp(r'[^0-9]'), '');
          final docIdDigits = docId.replaceAll(RegExp(r'[^0-9]'), '');
          if (sAdmDigits == digitsOnly || sIdDigits == digitsOnly || docIdDigits == digitsOnly) {
            return await _enrichStudentParentContact(s);
          }
        }

        // Alphanumeric stripped match (e.g. ADM-44424 matches ADM44424)
        final cleanAlphanumeric = clean.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final sAdmAlphanumeric = sAdm.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        final sIdAlphanumeric = sId.replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (cleanAlphanumeric.isNotEmpty &&
            (sAdmAlphanumeric == cleanAlphanumeric || sIdAlphanumeric == cleanAlphanumeric)) {
          return await _enrichStudentParentContact(s);
        }
      }

      // 4. Fallback: check `users` collection for role=student
      final userSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      for (final doc in userSnap.docs) {
        final data = doc.data();
        final u = SAMSUser.fromMap(data);

        final uId = u.id.trim().toUpperCase();
        final uDocId = doc.id.trim().toUpperCase();
        final uUsername = u.username.trim().toUpperCase();
        final uAdm = (data['admissionNumber'] ?? data['admission'] ?? data['studentId'] ?? '').toString().trim().toUpperCase();
        final uName = u.name.trim().toUpperCase();

        if (uId == clean || uDocId == clean || uUsername == clean || uAdm == clean || uName == clean) {
          return SAMSStudentProfile(
            id: u.id,
            admissionNumber: uAdm.isNotEmpty ? uAdm : clean,
            name: u.name,
            classRoom: u.classRoom ?? '',
            grade: u.grade ?? '',
            parentContact: u.parentContact ?? '',
            school: u.school,
            classTeacher: u.classTeacher,
          );
        }

        if (digitsOnly.length >= 4) {
          final uAdmDigits = uAdm.replaceAll(RegExp(r'[^0-9]'), '');
          final uIdDigits = uId.replaceAll(RegExp(r'[^0-9]'), '');
          final uDocIdDigits = uDocId.replaceAll(RegExp(r'[^0-9]'), '');
          final uUsernameDigits = uUsername.replaceAll(RegExp(r'[^0-9]'), '');
          if (uAdmDigits == digitsOnly || uIdDigits == digitsOnly || uDocIdDigits == digitsOnly || uUsernameDigits == digitsOnly) {
            return SAMSStudentProfile(
              id: u.id,
              admissionNumber: uAdm.isNotEmpty ? uAdm : clean,
              name: u.name,
              classRoom: u.classRoom ?? '',
              grade: u.grade ?? '',
              parentContact: u.parentContact ?? '',
              school: u.school,
              classTeacher: u.classTeacher,
            );
          }
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to find student by admission number',
          tag: 'DB', error: e, stackTrace: st);
    }
    return null;
  }

  /// Helper to enrich student profile with parent contact from users collection if missing
  Future<SAMSStudentProfile> _enrichStudentParentContact(SAMSStudentProfile student) async {
    if (student.parentContact.trim().isNotEmpty) return student;

    try {
      final userSnap = await _db.collection('users').doc(student.id).get();
      if (userSnap.exists && userSnap.data() != null) {
        final uData = userSnap.data()!;
        final phone = (uData['parentContact'] ?? uData['parentPhone'] ?? uData['phone'] ?? uData['mobile'] ?? uData['contact'])?.toString().trim();
        if (phone != null && phone.isNotEmpty) {
          return SAMSStudentProfile(
            id: student.id,
            admissionNumber: student.admissionNumber,
            name: student.name,
            classRoom: student.classRoom,
            grade: student.grade,
            parentContact: phone,
            school: student.school ?? uData['school']?.toString(),
            classTeacher: student.classTeacher ?? uData['classTeacher']?.toString(),
          );
        }
      }
    } catch (_) {}

    return student;
  }

  /// Check whether a verified parent account is already registered for this student admission number.
  Future<bool> isParentRegisteredForStudent(String studentAdmissionNumber) async {
    final parent = await getParentForStudent(studentAdmissionNumber);
    return parent != null;
  }

  /// Finds the registered parent user associated with a given student admission number.
  Future<SAMSUser?> getParentForStudent(String studentAdmissionNumber) async {
    final raw = studentAdmissionNumber.trim();
    if (raw.isEmpty) return null;

    final clean = raw.toLowerCase();
    final cleanUpper = raw.toUpperCase();
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      // 1. Resolve student profile to get all associated student IDs, admission numbers, and contact info
      final student = await findStudentByAdmissionNumber(raw);

      final Set<String> targetIds = {
        clean,
        cleanUpper.toLowerCase(),
      };
      if (student != null) {
        targetIds.add(student.id.trim().toLowerCase());
        if (student.admissionNumber != null && student.admissionNumber!.trim().isNotEmpty) {
          targetIds.add(student.admissionNumber!.trim().toLowerCase());
        }
      }

      // 2. Query all parent users in Firestore
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final u = SAMSUser.fromMap({'id': doc.id, ...data});
        final linkedSid = (u.studentId ?? data['studentAdmission'] ?? data['admissionNumber'] ?? '').toString().trim().toLowerCase();
        final parentPhone = (u.parentContact ?? data['phone'] ?? data['mobile'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');

        // Check against any target student IDs / admission numbers
        for (final tid in targetIds) {
          if (tid.isNotEmpty && (linkedSid == tid || linkedSid.contains(tid) || tid.contains(linkedSid))) {
            return u;
          }
        }

        // Check numeric digit match (e.g. 44424)
        if (digitsOnly.length >= 4) {
          final linkedDigits = linkedSid.replaceAll(RegExp(r'[^0-9]'), '');
          if (linkedDigits == digitsOnly || linkedDigits.endsWith(digitsOnly) || digitsOnly.endsWith(linkedDigits)) {
            return u;
          }
        }

        // Check parent phone match against student's parent contact
        if (student != null && student.parentContact.isNotEmpty && parentPhone.isNotEmpty) {
          final sPhoneDigits = student.parentContact.replaceAll(RegExp(r'[^0-9]'), '');
          if (sPhoneDigits.length >= 7 && parentPhone.length >= 7) {
            if (sPhoneDigits.endsWith(parentPhone.substring(parentPhone.length - 7)) ||
                parentPhone.endsWith(sPhoneDigits.substring(sPhoneDigits.length - 7))) {
              return u;
            }
          }
        }
      }

      // 3. Check if student document in `students` collection already has `isParentRegistered: true`
      if (student != null) {
        final doc = await _db.collection('students').doc(student.id).get();
        if (doc.exists && doc.data() != null) {
          final sData = doc.data()!;
          if (sData['isParentRegistered'] == true || sData['parentVerified'] == true) {
            return SAMSUser(
              id: 'parent-${student.id}',
              username: 'parent_${student.id}',
              name: 'Verified Parent',
              role: UserRole.parent,
              studentId: student.id,
              parentContact: student.parentContact,
              school: student.school,
            );
          }
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to check parent registration status',
          tag: 'DB', error: e, stackTrace: st);
    }
    return null;
  }

  /// Find student profile for a parent by student ID or registered parent contact number.
  Future<SAMSStudentProfile?> findStudentForParent({
    String? studentId,
    String? parentContact,
  }) async {
    final cleanSid = studentId?.trim() ?? '';
    final cleanPhone = parentContact?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';

    AppLogger.db('Looking up student profile for parent',
        collection: 'students', data: 'studentId=$cleanSid | phone=$cleanPhone');

    try {
      // 1. Direct ID lookup if student ID was provided
      if (cleanSid.isNotEmpty) {
        final direct = await getStudentById(cleanSid);
        if (direct != null) return direct;

        // Try case-insensitive lookup across students
        final snap = await _db.collection('students').get();
        for (final doc in snap.docs) {
          final s = SAMSStudentProfile.fromMap(doc.data());
          if (s.id.trim().toLowerCase() == cleanSid.toLowerCase()) {
            return s;
          }
        }
      }

      // 2. Lookup by parent contact number
      if (cleanPhone.isNotEmpty) {
        final snap = await _db.collection('students').get();
        for (final doc in snap.docs) {
          final s = SAMSStudentProfile.fromMap(doc.data());
          final sPhone = s.parentContact.replaceAll(RegExp(r'[^0-9+]'), '');
          if (sPhone.isNotEmpty &&
              (sPhone == cleanPhone ||
                  (sPhone.length >= 7 && cleanPhone.length >= 7 &&
                      (sPhone.endsWith(cleanPhone.substring(cleanPhone.length - 7)) ||
                          cleanPhone.endsWith(sPhone.substring(sPhone.length - 7)))))) {
            AppLogger.info('Linked student profile found by contact: ${s.name} (${s.id})',
                tag: 'DB');
            return s;
          }
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to link student for parent',
          tag: 'DB', error: e, stackTrace: st);
    }
    return null;
  }

  // ─── Real-time Attendance Stream ──────────────────────────────────────────

  /// Real-time stream of attendance records for a student.
  /// Automatically fires whenever a teacher marks or updates attendance.
  Stream<List<AttendanceRecord>> streamAttendanceForStudent(String studentId) {
    if (studentId.trim().isEmpty) return const Stream.empty();
    final cleanSid = studentId.trim();
    return _db
        .collection('attendance')
        .where('studentId', isEqualTo: cleanSid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id}))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ─── Parent Notifications & Real-time Stream ──────────────────────────────

  /// Real-time stream of parent notifications.
  /// Fires immediately when teacher records absence, lateness, or updates attendance.
  Stream<List<ParentNotification>> streamParentNotifications(
    String studentId, {
    String? parentContact,
  }) {
    final cleanSid = studentId.trim().toLowerCase();
    final cleanPhone =
        parentContact?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';

    if (cleanSid.isEmpty && cleanPhone.isEmpty) {
      return const Stream.empty();
    }

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    return _db.collection('parent_notifications').snapshots().map((snap) {
      final list = snap.docs.map((d) {
        return ParentNotification.fromMap({...d.data(), 'id': d.id});
      }).where((n) {
        // ── Auto-expire: skip notifications older than 24 hours ──────────
        final ts = DateTime.tryParse(n.timestamp);
        if (ts != null && ts.isBefore(cutoff)) return false;

        final nSid = n.studentId.trim().toLowerCase();
        final nPhone =
            (n.parentContact ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

        // STRICT FILTER: If student ID is specified, only match this exact student!
        if (cleanSid.isNotEmpty) {
          return nSid == cleanSid;
        }

        // Fallback: only if no student ID was provided, match exact phone number
        if (cleanPhone.isNotEmpty && nPhone.isNotEmpty) {
          return nPhone == cleanPhone;
        }
        return false;
      }).toList();

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Delete a parent notification document from Firestore
  Future<void> deleteParentNotification(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      await _db
          .collection('parent_notifications')
          .doc(notificationId)
          .delete();
      AppLogger.db('Parent notification deleted',
          collection: 'parent_notifications', data: notificationId);
    } catch (e, st) {
      AppLogger.error('Failed to delete parent notification',
          tag: 'DB', error: e, stackTrace: st);
    }
  }

  /// Fetch all notifications for a student / parent (one-time fetch)
  Future<List<ParentNotification>> getParentNotifications(
    String studentId, {
    String? parentContact,
  }) async {
    final cleanSid = studentId.trim().toLowerCase();
    final cleanPhone =
        parentContact?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';

    if (cleanSid.isEmpty && cleanPhone.isEmpty) return [];

    AppLogger.db('Querying parent notifications',
        collection: 'parent_notifications',
        action: 'get',
        data: 'studentId=$cleanSid | phone=$cleanPhone');

    try {
      final snap = await _db.collection('parent_notifications').get();

      final list = snap.docs
          .map((d) => ParentNotification.fromMap({...d.data(), 'id': d.id}))
          .where((n) {
        final nSid = n.studentId.trim().toLowerCase();
        final nPhone =
            (n.parentContact ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

        // STRICT FILTER: If student ID is specified, only match this exact student!
        if (cleanSid.isNotEmpty) {
          return nSid == cleanSid;
        }

        // Fallback: only if no student ID was provided, match exact phone number
        if (cleanPhone.isNotEmpty && nPhone.isNotEmpty) {
          return nPhone == cleanPhone;
        }
        return false;
      }).toList();

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      AppLogger.db('Parent notifications retrieved: ${list.length}',
          collection: 'parent_notifications');
      return list;
    } catch (e, st) {
      AppLogger.error('Failed to fetch parent notifications',
          tag: 'DB', error: e, stackTrace: st);
      return [];
    }
  }

  /// Mark a parent notification as read in Firestore
  Future<void> markParentNotificationAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      await _db
          .collection('parent_notifications')
          .doc(notificationId)
          .update({'read': true});
      AppLogger.db('Parent notification marked read',
          collection: 'parent_notifications', data: notificationId);
    } catch (e, st) {
      AppLogger.error('Failed to mark notification read',
          tag: 'DB', error: e, stackTrace: st);
    }
  }

  /// Create a parent notification in Firestore
  Future<void> createParentNotification(ParentNotification notif) async {
    try {
      await _db
          .collection('parent_notifications')
          .doc(notif.id)
          .set(notif.toMap());
      AppLogger.db('Parent notification created',
          collection: 'parent_notifications', data: notif.id);
    } catch (e, st) {
      AppLogger.error('Failed to create parent notification',
          tag: 'DB', error: e, stackTrace: st);
    }
  }
}
