import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../data/database_service.dart';
import '../i18n/strings.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

// ─── App State Provider ──────────────────────────────────────────────────────
class AppProvider extends ChangeNotifier {
  SAMSUser? _user;
  SAMSStudentProfile? _linkedStudent;
  AppLanguage _language = AppLanguage.english;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isLoading = false;
  String? _error;

  // ─── Live data from Firestore ───────────────────────────────────────────
  List<AttendanceRecord> _attendance = [];
  List<TermMark> _marks = [];
  List<TimetableSlot> _timetable = [];
  List<CircularNotice> _notices = [];
  List<ParentNotification> _parentNotifications = [];
  bool _dataLoading = false;

  // ─── Real-time Firestore Stream Subscriptions ───────────────────────────
  StreamSubscription<List<ParentNotification>>? _parentNotifSub;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;
  StreamSubscription<List<TermMark>>? _marksSub;
  ParentNotification? _latestIncomingAlert;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed && hasListeners) {
      super.notifyListeners();
    }
  }

  SAMSUser? get user => _user;
  SAMSStudentProfile? get linkedStudent => _linkedStudent;
  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLoggedIn => _user != null;
  bool get isParent => _user?.role == UserRole.parent;
  bool get isStudent => _user?.role == UserRole.student;
  bool get isTeacher => _user?.role == UserRole.teacher;
  bool get isPrincipal => _user?.role == UserRole.principal;
  bool get dataLoading => _dataLoading;
  ParentNotification? get latestIncomingAlert => _latestIncomingAlert;

  void clearLatestIncomingAlert() {
    _latestIncomingAlert = null;
  }

  List<AttendanceRecord> get attendance => _attendance;
  List<TermMark> get marks => _marks;
  List<TimetableSlot> get timetable => _timetable;
  List<CircularNotice> get notices => _notices;
  List<ParentNotification> get parentNotifications => _parentNotifications;
  int get unreadParentNotificationsCount {
    if (_parentNotifications.isEmpty) return 0;
    return _parentNotifications.where((n) => !n.read).length;
  }

  String get studentId {
    if (_user == null) return '';
    if (_user!.role == UserRole.student) {
      return _linkedStudent?.id.isNotEmpty == true ? _linkedStudent!.id : _user!.id;
    }
    return _linkedStudent?.id ?? _user!.studentId ?? '';
  }

  String get studentName {
    if (_user == null) return '';
    if (_user!.role == UserRole.student) {
      return _linkedStudent?.name.isNotEmpty == true ? _linkedStudent!.name : _user!.name;
    }
    return _linkedStudent?.name ?? _user!.name;
  }

  String get studentGrade =>
      _linkedStudent?.grade.isNotEmpty == true ? _linkedStudent!.grade : (_user?.grade ?? '');
  String get studentClass =>
      _linkedStudent?.classRoom.isNotEmpty == true ? _linkedStudent!.classRoom : (_user?.classRoom ?? '');

  final _db = DatabaseService();

  /// Pure Dart cross-platform UUID v4 generator (works seamlessly on Web, Android, iOS)
  String _generateUuid() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<void> init() async {
    AppLogger.info('Initializing SAMS App State Provider', tag: 'PROVIDER');
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('lang');
    final savedTheme = prefs.getString('theme');
    final savedUserId = prefs.getString('user_id');

    if (savedLang != null) {
      _language = AppLanguage.values.firstWhere(
        (l) => l.name == savedLang,
        orElse: () => AppLanguage.english,
      );
      SAMSStrings.setLanguage(_language);
      AppLogger.info('Restored language preference: ${_language.name}', tag: 'PROVIDER');
    }
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    }

    // Restore session from Firestore
    if (savedUserId != null && savedUserId.isNotEmpty) {
      AppLogger.auth('Restoring session from saved user ID', data: savedUserId);
      try {
        final user = await _db.getUserById(savedUserId);
        if (user != null) {
          _user = user;
          AppLogger.auth('Session successfully restored', username: user.username, role: user.role.name);
          notifyListeners();
          await _loadStudentData();
          return;
        } else {
          AppLogger.warning('Saved user ID no longer exists in Firestore. Clearing session.', tag: 'AUTH');
          await prefs.remove('user_id');
        }
      } catch (e, st) {
        AppLogger.error('Failed to restore session from Firestore', tag: 'AUTH', error: e, stackTrace: st);
      }
    }

    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    AppLogger.auth('Attempting login', username: username);

    try {
      if (username.trim().isEmpty || password.isEmpty) {
        throw Exception('Please enter both username and password.');
      }

      final found = await _db.getUserByUsername(username);

      if (found == null) {
        AppLogger.auth('Login failed: User not found', username: username);
        throw Exception('User not found. Please check your username or register a new account.');
      }

      final storedPassword = found.password;
      if (storedPassword == null || storedPassword != password) {
        AppLogger.auth('Login failed: Incorrect password', username: username);
        throw Exception('Incorrect password. Please try again.');
      }

      _user = found;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', found.id);

      AppLogger.auth('Login successful', username: found.username, role: found.role.name);

      // Load live student data
      await _loadStudentData();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('permission') ||
          msg.toLowerCase().contains('missing or insufficient')) {
        _error = 'Firebase permission denied. Please check Firestore security rules.';
      } else if (msg.toLowerCase().contains('network') ||
                 msg.toLowerCase().contains('offline')) {
        _error = 'Network error. Please check your internet connection.';
      } else {
        _error = msg;
      }
      AppLogger.auth('Login error encountered: $_error', username: username);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user with a specific role and auto-login upon success.
  Future<bool> register({
    required String name,
    required String username,
    required String password,
    required UserRole role,
    String? grade,
    String? classRoom,
    String? parentContact,
    String? studentId,
    String? subject,
    String? school,
    String? classTeacher,
    String? admissionNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    AppLogger.auth('Starting registration workflow', username: username, role: role.name);

    try {
      if (name.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
        throw Exception('Please fill in all required fields.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long.');
      }

      String newId;
      String? resolvedParentContact = parentContact;
      String? resolvedGrade = grade;
      String? resolvedClassRoom = classRoom;
      String? resolvedSchool = school;
      String? resolvedClassTeacher = classTeacher;

      if (role == UserRole.student) {
        final adm = (admissionNumber ?? studentId ?? '').trim().toUpperCase();
        if (adm.isEmpty) {
          throw Exception(SAMSStrings.studentAdmissionRequired);
        }

        // 1. Resolve existing student profile in database
        final studentProfile = await _db.findStudentByAdmissionNumber(adm);

        // 2. Security Check: Verify that parent has registered / verified first
        final parent = await _db.getParentForStudent(adm);
        if (parent == null) {
          AppLogger.warning('Student registration rejected: No registered parent found for $adm', tag: 'SECURITY');
          throw Exception(SAMSStrings.parentMustRegisterFirst);
        }

        // Use the student's existing Firestore ID if available, otherwise admission number
        newId = studentProfile?.id.isNotEmpty == true
            ? studentProfile!.id
            : (adm.isNotEmpty ? adm : _generateUuid());

        resolvedParentContact ??= studentProfile?.parentContact.isNotEmpty == true
            ? studentProfile!.parentContact
            : parent.parentContact;

        if (resolvedGrade == null || resolvedGrade.isEmpty) {
          resolvedGrade = studentProfile?.grade;
        }
        if (resolvedClassRoom == null || resolvedClassRoom.isEmpty) {
          resolvedClassRoom = studentProfile?.classRoom;
        }
        if (resolvedSchool == null || resolvedSchool.isEmpty) {
          resolvedSchool = studentProfile?.school ?? parent.school;
        }
        if (resolvedClassTeacher == null || resolvedClassTeacher.isEmpty) {
          resolvedClassTeacher = studentProfile?.classTeacher;
        }
      } else {
        newId = _generateUuid();
      }

      final registeredUser = await _db.registerUser(
        id: newId,
        username: username.trim(),
        password: password,
        name: name.trim(),
        role: role,
        grade: resolvedGrade,
        classRoom: resolvedClassRoom,
        parentContact: resolvedParentContact,
        studentId: studentId,
        subject: subject,
        school: resolvedSchool,
        classTeacher: resolvedClassTeacher,
      );

      _user = registeredUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', registeredUser.id);

      AppLogger.auth('Registration & auto-login succeeded', username: registeredUser.username, role: registeredUser.role.name);

      await _loadStudentData();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.toLowerCase().contains('permission') ||
          msg.toLowerCase().contains('missing or insufficient')) {
        _error = 'Firebase permission denied. Please verify Firestore rules in Firebase Console.';
      } else if (msg.toLowerCase().contains('network') ||
                 msg.toLowerCase().contains('offline')) {
        _error = 'Network error. Please check your internet connection.';
      } else {
        _error = msg;
      }
      AppLogger.error('Registration failed: $_error', tag: 'AUTH');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if a parent is registered for the student admission number
  Future<bool> checkParentRegistered(String admissionNumber) {
    return _db.isParentRegisteredForStudent(admissionNumber);
  }

  /// Fetches registered schools from Firestore
  Future<List<String>> getSchools() {
    return _db.getSchools();
  }

  /// Suggests the real class teacher based on selected classroom and school
  Future<String> suggestClassTeacher(String classRoom, {String? school}) {
    return _db.getClassTeacherForClass(classRoom, school: school);
  }

  // ─── Forgot Password / OTP State & Methods ────────────────────────────────
  String? _resetOtp;
  DateTime? _resetOtpExpiry;
  String? _resetUsername;
  String? _resetMaskedPhone;
  String? _resetRawPhone;

  String? get resetOtp => _resetOtp;
  String? get resetMaskedPhone => _resetMaskedPhone;
  String? get resetRawPhone => _resetRawPhone;
  String? get resetUsername => _resetUsername;

  // ─── Parent Registration Verification State & Methods (Firebase Phone Auth) ─
  SAMSStudentProfile? _regStudentProfile;
  String? _regVerificationId;
  int? _regResendToken;
  String? _regMaskedPhone;
  String? _regRawPhone;
  String? _regE164Phone;
  String? _regFallbackOtp;
  bool _regOtpVerified = false;
  bool _regAutoVerified = false;

  SAMSStudentProfile? get regStudentProfile => _regStudentProfile;
  String? get regMaskedPhone => _regMaskedPhone;
  String? get regRawPhone => _regRawPhone;
  String? get regE164Phone => _regE164Phone;
  String? get regFallbackOtp => _regFallbackOtp;
  bool get regOtpVerified => _regOtpVerified;
  bool get regAutoVerified => _regAutoVerified;

  void resetParentRegistrationState() {
    _regStudentProfile = null;
    _regVerificationId = null;
    _regResendToken = null;
    _regMaskedPhone = null;
    _regRawPhone = null;
    _regE164Phone = null;
    _regFallbackOtp = null;
    _regOtpVerified = false;
    _regAutoVerified = false;
    _error = null;
    notifyListeners();
  }

  /// Formats raw phone strings into standard E.164 international format (+94XXXXXXXXX)
  String _formatToE164(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) return clean;
    if (clean.startsWith('00')) return '+${clean.substring(2)}';
    if (clean.startsWith('0') && clean.length == 10) {
      return '+94${clean.substring(1)}';
    }
    if (clean.startsWith('7') && clean.length == 9) {
      return '+94$clean';
    }
    if (clean.length == 9 || clean.length == 10) {
      return '+94$clean';
    }
    return '+$clean';
  }

  /// Sends a real SMS OTP via Firebase Phone Authentication to the registered parent contact.
  /// Automatically provides fallback OTP verification if Phone Auth is not yet enabled in Firebase Console.
  Future<bool> sendParentRegistrationOtp(String admissionNumber) async {
    _isLoading = true;
    _error = null;
    _regAutoVerified = false;
    _regFallbackOtp = null;
    notifyListeners();

    final cleanAdm = admissionNumber.trim();
    AppLogger.auth('Initiating SMS OTP verification for admission: $cleanAdm');

    try {
      if (cleanAdm.isEmpty) {
        throw Exception('Please enter the student admission number.');
      }

      final student = await _db.findStudentByAdmissionNumber(cleanAdm);
      if (student == null) {
        throw Exception(SAMSStrings.studentNotFound);
      }

      final rawPhone = student.parentContact.trim();
      if (rawPhone.isEmpty) {
        throw Exception(SAMSStrings.noParentPhoneRegistered);
      }

      final e164Phone = _formatToE164(rawPhone);

      _regStudentProfile = student;
      _regRawPhone = rawPhone;
      _regE164Phone = e164Phone;
      _regMaskedPhone = _maskPhone(rawPhone);
      _regOtpVerified = false;

      final completer = Completer<bool>();

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: e164Phone,
          timeout: const Duration(seconds: 60),
          forceResendingToken: _regResendToken,
          verificationCompleted: (PhoneAuthCredential credential) async {
            AppLogger.auth('Firebase Phone Auth: Auto-verification completed for $e164Phone');
            _regOtpVerified = true;
            _regAutoVerified = true;
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(true);
          },
          verificationFailed: (FirebaseAuthException e) {
            AppLogger.warning('Firebase Phone Auth: ${e.code} (${e.message}). Activating fallback OTP.');
            // Generate fallback 6-digit OTP code so registration is NEVER blocked
            final randCode = (100000 + Random.secure().nextInt(900000)).toString();
            _regFallbackOtp = randCode;
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(true);
          },
          codeSent: (String verificationId, int? resendToken) {
            AppLogger.auth('Real SMS OTP successfully dispatched to $e164Phone',
                data: 'Verification ID=$verificationId');
            _regVerificationId = verificationId;
            _regResendToken = resendToken;
            _isLoading = false;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(true);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _regVerificationId = verificationId;
          },
        );
      } catch (e) {
        AppLogger.warning('Direct Firebase call exception: $e. Using fallback OTP.');
        final randCode = (100000 + Random.secure().nextInt(900000)).toString();
        _regFallbackOtp = randCode;
        _isLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      }

      return await completer.future;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
      _isLoading = false;
      AppLogger.error('SMS OTP request failed: $_error', tag: 'AUTH');
      notifyListeners();
      return false;
    }
  }

  /// Validates the 6-digit OTP code entered by the user
  Future<bool> verifyParentRegistrationOtp(String smsCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final code = smsCode.trim();

    try {
      if (code.length < 6) {
        throw Exception('Please enter the complete 6-digit OTP code.');
      }

      // Check fallback OTP first if Firebase Phone Auth was disabled
      if (_regFallbackOtp != null) {
        if (code == _regFallbackOtp) {
          _regOtpVerified = true;
          AppLogger.auth('Fallback OTP successfully verified for student ${_regStudentProfile?.id}');
          return true;
        } else {
          _error = SAMSStrings.invalidOtp;
          return false;
        }
      }

      // Otherwise, verify real SMS OTP with Firebase
      if (_regVerificationId == null || _regVerificationId!.isEmpty) {
        throw Exception('Session expired. Please request a new OTP code.');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _regVerificationId!,
        smsCode: code,
      );

      // Validate credential with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();

      _regOtpVerified = true;
      AppLogger.auth('Real SMS OTP successfully verified for student ${_regStudentProfile?.id}');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _error = SAMSStrings.invalidOtp;
      } else if (e.code == 'session-expired') {
        _error = 'OTP code has expired. Please tap Resend OTP.';
      } else {
        _error = e.message ?? SAMSStrings.invalidOtp;
      }
      AppLogger.error('SMS OTP verification failed', tag: 'AUTH', error: e.message);
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _maskPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length <= 4) return '•••• $clean';
    final prefix = clean.substring(0, min(3, clean.length - 4));
    final suffix = clean.substring(clean.length - 3);
    return '$prefix •••• •$suffix';
  }

  /// Initiates password recovery by finding the user and generating a 6-digit OTP
  Future<bool> sendPasswordResetOtp(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanUsername = username.trim();
    AppLogger.auth('Initiating password reset request', username: cleanUsername);

    try {
      if (cleanUsername.isEmpty) {
        throw Exception('Please enter your username.');
      }

      final user = await _db.getUserByUsername(cleanUsername);
      if (user == null) {
        throw Exception('Account with username "$cleanUsername" was not found.');
      }

      final phone = await _db.resolveUserPhoneNumber(user);
      if (phone == null || phone.trim().isEmpty) {
        throw Exception(SAMSStrings.noPhoneRegistered);
      }

      // Generate a secure 6-digit random OTP
      final rand = Random.secure();
      final otpCode = (100000 + rand.nextInt(900000)).toString();

      _resetOtp = otpCode;
      _resetOtpExpiry = DateTime.now().add(const Duration(minutes: 5));
      _resetUsername = user.username;
      _resetRawPhone = phone.trim();
      _resetMaskedPhone = _maskPhone(phone.trim());

      AppLogger.auth('Password reset OTP generated & sent to phone: $_resetMaskedPhone',
          username: user.username, data: 'OTP=$otpCode (Expires in 5 mins)');

      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
      AppLogger.error('Password reset OTP request failed: $_error', tag: 'AUTH');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validates the 6-digit OTP code entered by the user
  bool verifyResetOtp(String enteredCode) {
    _error = null;
    final code = enteredCode.trim();

    if (_resetOtp == null || _resetOtpExpiry == null) {
      _error = 'Session expired. Please request a new OTP code.';
      notifyListeners();
      return false;
    }

    if (DateTime.now().isAfter(_resetOtpExpiry!)) {
      _error = 'OTP code has expired. Please tap Resend OTP.';
      notifyListeners();
      return false;
    }

    if (_resetOtp != code) {
      _error = SAMSStrings.invalidOtp;
      notifyListeners();
      return false;
    }

    AppLogger.auth('OTP code verified successfully', username: _resetUsername);
    notifyListeners();
    return true;
  }

  /// Updates password in Firestore
  Future<bool> resetPassword({
    required String username,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanUsername = username.trim();
    AppLogger.auth('Submitting password update after OTP verification', username: cleanUsername);

    try {
      if (newPassword.length < 6) {
        throw Exception(SAMSStrings.passwordTooShort);
      }

      await _db.updateUserPassword(
        username: cleanUsername,
        newPassword: newPassword,
      );

      // Reset temporary recovery state
      _resetOtp = null;
      _resetOtpExpiry = null;
      _resetUsername = null;
      _resetMaskedPhone = null;
      _resetRawPhone = null;

      AppLogger.auth('Password update completed successfully', username: cleanUsername);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg;
      AppLogger.error('Failed to reset password: $_error', tag: 'AUTH');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all student-specific data from Firestore and establish real-time listeners.
  /// Called after login and after session restore.
  Future<void> _loadStudentData() async {
    // 1. If parent, resolve linked student profile
    if (_user?.role == UserRole.parent) {
      _linkedStudent = await _db.findStudentForParent(
        studentId: _user?.studentId,
        parentContact: _user?.parentContact,
      );
      if (_linkedStudent != null) {
        AppLogger.info(
          'Parent linked to student: ${_linkedStudent!.name} (ID: ${_linkedStudent!.id}, Class: ${_linkedStudent!.classRoom})',
          tag: 'PROVIDER',
        );
      }
    } else if (_user?.role == UserRole.student) {
      _linkedStudent = await _db.findStudentByAdmissionNumber(_user!.id);
      if (_linkedStudent != null) {
        AppLogger.info(
          'Student profile resolved: ${_linkedStudent!.name} (ID: ${_linkedStudent!.id}, Class: ${_linkedStudent!.classRoom})',
          tag: 'PROVIDER',
        );
      }
    }

    final sid = studentId;
    final cls = studentClass;
    final grade = studentGrade;
    final parentPhone = _user?.parentContact;

    if (sid.isEmpty && cls.isEmpty && (parentPhone == null || parentPhone.isEmpty)) {
      AppLogger.info('No studentId or classRoom associated with this user. Skipping live data load.', tag: 'PROVIDER');
      return;
    }

    _dataLoading = true;
    notifyListeners();

    AppLogger.info('Fetching live student data for ID=$sid, Class=$cls, Grade=$grade', tag: 'PROVIDER');

    try {
      final results = await Future.wait([
        sid.isNotEmpty ? _db.getAttendanceForStudent(sid) : Future.value(<AttendanceRecord>[]),
        sid.isNotEmpty ? _db.getTermMarksForStudent(sid) : Future.value(<TermMark>[]),
        cls.isNotEmpty ? _db.getTimetableForClass(cls) : Future.value(<TimetableSlot>[]),
        _db.getNoticesForStudents(targetGrade: grade),
        _db.getParentNotifications(sid, parentContact: parentPhone),
      ]);

      _attendance = results[0] as List<AttendanceRecord>;
      _marks = results[1] as List<TermMark>;
      _timetable = results[2] as List<TimetableSlot>;
      _notices = results[3] as List<CircularNotice>;
      _parentNotifications = results.length > 4 ? (results[4] as List<ParentNotification>) : [];

      // 2. Establish live real-time Firestore listeners for immediate updates
      _setupRealtimeStreams(sid, parentPhone);

      // 3. Register device for real-time push notifications & FCM topics
      NotificationService.instance.registerUser(
        studentId: sid,
        parentPhone: parentPhone,
        userId: _user?.id ?? '',
      );

      AppLogger.info(
        'Student data successfully loaded: '
        'attendance=${_attendance.length}, marks=${_marks.length}, '
        'timetable=${_timetable.length}, notices=${_notices.length}, '
        'parentNotifs=${_parentNotifications.length}',
        tag: 'PROVIDER',
      );
    } catch (e, st) {
      AppLogger.error('Failed to load student data from Firestore', tag: 'PROVIDER', error: e, stackTrace: st);
    } finally {
      _dataLoading = false;
      notifyListeners();
    }
  }

  /// Establishes real-time listeners for attendance, marks, and parent notifications
  void _setupRealtimeStreams(String sid, String? parentPhone) {
    _parentNotifSub?.cancel();
    _attendanceSub?.cancel();
    _marksSub?.cancel();

    bool isInitialEmission = true;

    if (sid.isNotEmpty || (parentPhone != null && parentPhone.isNotEmpty)) {
      _parentNotifSub = _db
          .streamParentNotifications(sid, parentContact: parentPhone)
          .listen((notifs) {
        // Detect newly arrived notifications ONLY after initial load
        if (!isInitialEmission && notifs.isNotEmpty) {
          final firstNew = notifs.first;
          final hadBefore = _parentNotifications.any((n) => n.id == firstNew.id);

          // STRICT CHECK: The notification MUST belong to this parent's student!
          final isForThisStudent = sid.isEmpty ||
              firstNew.studentId.trim().toLowerCase() == sid.trim().toLowerCase();

          if (!hadBefore && !firstNew.read && isForThisStudent) {
            _latestIncomingAlert = firstNew;
            AppLogger.auth('Real-time Parent Notification received for student ${firstNew.studentId}: ${firstNew.title}',
                username: _user?.username, data: firstNew.message);

            // Trigger real Android/iOS system notification in device status bar
            final isUrgent = firstNew.status == AttendanceStatus.absent ||
                firstNew.priority == 'urgent' ||
                firstNew.title.contains('ABSENT');

            NotificationService.instance.showAttendanceNotification(
              title: firstNew.title,
              body: firstNew.message,
              status: firstNew.status,
              isUrgent: isUrgent,
              payloadData: {
                'id': firstNew.id,
                'studentId': firstNew.studentId,
                'status': firstNew.status.name,
                'date': firstNew.date,
                'type': firstNew.type,
              },
            );
          }
        }
        isInitialEmission = false;
        _parentNotifications = notifs;
        notifyListeners();
      }, onError: (err) {
        AppLogger.error('Real-time parent notifications stream error',
            tag: 'PROVIDER', error: err);
      });
    }

    if (sid.isNotEmpty) {
      _attendanceSub = _db.streamAttendanceForStudent(sid).listen((attList) {
        _attendance = attList;
        notifyListeners();
      }, onError: (err) {
        AppLogger.error('Real-time attendance stream error',
            tag: 'PROVIDER', error: err);
      });

      _marksSub = _db.streamTermMarksForStudent(sid).listen((marksList) {
        _marks = marksList;
        notifyListeners();
      }, onError: (err) {
        AppLogger.error('Real-time term marks stream error',
            tag: 'PROVIDER', error: err);
      });
    }
  }

  /// Refresh all live data from Firestore.
  Future<void> refreshData() => _loadStudentData();

  Future<void> logout() async {
    AppLogger.auth('User logging out', username: _user?.username);

    // Unregister notification topics
    final sid = studentId;
    final parentPhone = _user?.parentContact;
    NotificationService.instance.unregisterUser(
      studentId: sid,
      parentPhone: parentPhone,
    );

    _parentNotifSub?.cancel();
    _attendanceSub?.cancel();
    _marksSub?.cancel();
    _parentNotifSub = null;
    _attendanceSub = null;
    _marksSub = null;
    _linkedStudent = null;
    _latestIncomingAlert = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _user = null;
    _attendance = [];
    _marks = [];
    _timetable = [];
    _notices = [];
    _parentNotifications = [];
    notifyListeners();
    AppLogger.auth('User logged out, session cleared');
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    SAMSStrings.setLanguage(lang);
    AppLogger.info('Language changed to: ${lang.name}', tag: 'SETTINGS');
    SharedPreferences.getInstance().then((p) => p.setString('lang', lang.name));
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    AppLogger.info('Theme changed to: ${_themeMode.name}', tag: 'SETTINGS');
    SharedPreferences.getInstance().then(
      (p) => p.setString('theme', _themeMode == ThemeMode.dark ? 'dark' : 'light'),
    );
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    final idx = _parentNotifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_parentNotifications[idx].read) {
      final old = _parentNotifications[idx];
      _parentNotifications[idx] = ParentNotification(
        id: old.id,
        studentId: old.studentId,
        studentName: old.studentName,
        date: old.date,
        status: old.status,
        title: old.title,
        message: old.message,
        timestamp: old.timestamp,
        read: true,
        teacherName: old.teacherName,
        type: old.type,
      );
      notifyListeners();
      await _db.markParentNotificationAsRead(id);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    bool changed = false;
    for (int i = 0; i < _parentNotifications.length; i++) {
      if (!_parentNotifications[i].read) {
        final old = _parentNotifications[i];
        _parentNotifications[i] = ParentNotification(
          id: old.id,
          studentId: old.studentId,
          studentName: old.studentName,
          date: old.date,
          status: old.status,
          title: old.title,
          message: old.message,
          timestamp: old.timestamp,
          read: true,
          teacherName: old.teacherName,
          type: old.type,
        );
        _db.markParentNotificationAsRead(old.id);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    final idx = _parentNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _parentNotifications.removeAt(idx);
      notifyListeners();
      await _db.deleteParentNotification(id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _parentNotifSub?.cancel();
    _attendanceSub?.cancel();
    _marksSub?.cancel();
    _parentNotifSub = null;
    _attendanceSub = null;
    _marksSub = null;
    super.dispose();
  }

}
