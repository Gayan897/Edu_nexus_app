import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_provider.dart';
import '../models/models.dart';
import '../i18n/strings.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _studentFormKey = GlobalKey<FormState>();
  final _parentProfileFormKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.student;

  // ─── Common & Student Controllers ──────────────────────────────────────────
  final _studentAdmissionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _parentContactCtrl = TextEditingController();
  final _classTeacherCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();

  List<String> _schools = [];
  bool _isLoadingSchools = false;
  String? _selectedSchool;
  bool _isCustomSchool = false;
  String _selectedGrade = '11';
  String _selectedClass = '11A';
  bool _showPassword = false;
  bool _isAutoSuggestingTeacher = false;

  final List<String> _grades = ['10', '11', '12', '13'];
  final List<String> _classes = [
    '10A', '10B', '10C',
    '11A', '11B', '11C',
    '12A', '12B', '12C',
    '13A', '13B', '13C',
  ];

  // ─── Parent Registration Specific State ────────────────────────────────────
  // Parent Steps: 1 = Admission Lookup, 2 = OTP Verification, 3 = Account Profile
  int _parentStep = 1;
  final _admissionIdCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _parentUsernameCtrl = TextEditingController();
  final _parentPasswordCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  bool _showParentPassword = false;

  // 6 OTP Digit Controllers & FocusNodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchoolsAndTeachers();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _studentAdmissionCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _parentContactCtrl.dispose();
    _classTeacherCtrl.dispose();
    _schoolCtrl.dispose();
    _admissionIdCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentUsernameCtrl.dispose();
    _parentPasswordCtrl.dispose();
    _parentPhoneCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Loads real registered schools from Firestore
  Future<void> _loadSchoolsAndTeachers() async {
    final provider = context.read<AppProvider>();
    setState(() => _isLoadingSchools = true);
    try {
      final realSchools = await provider.getSchools();
      if (mounted) {
        setState(() {
          _schools = realSchools;
          if (_schools.isNotEmpty) {
            _selectedSchool = _schools.first;
            _schoolCtrl.text = _schools.first;
            _isCustomSchool = false;
          } else {
            _isCustomSchool = true;
          }
          _isLoadingSchools = false;
        });
        await _updateClassTeacherSuggestion();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
          _isCustomSchool = true;
        });
      }
    }
  }

  /// Automatically resolves and updates the class teacher name from real Firestore data
  Future<void> _updateClassTeacherSuggestion() async {
    final provider = context.read<AppProvider>();
    final currentSchool = _isCustomSchool
        ? _schoolCtrl.text.trim()
        : (_selectedSchool ?? '');
    setState(() => _isAutoSuggestingTeacher = true);
    final teacher = await provider.suggestClassTeacher(
      _selectedClass,
      school: currentSchool.isNotEmpty ? currentSchool : null,
    );
    if (mounted) {
      setState(() {
        _classTeacherCtrl.text = teacher;
        _isAutoSuggestingTeacher = false;
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
          _resendCountdown = 0;
        });
      }
    });
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  // ─── Student Direct Register ───────────────────────────────────────────────
  Future<void> _handleStudentRegister() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();

    if (!_studentFormKey.currentState!.validate()) return;

    final admission = _studentAdmissionCtrl.text.trim().toUpperCase();
    final effectiveSchool = _isCustomSchool
        ? _schoolCtrl.text.trim()
        : (_selectedSchool ?? _schoolCtrl.text.trim());

    final success = await provider.register(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: UserRole.student,
      admissionNumber: admission,
      grade: _selectedGrade,
      classRoom: _selectedClass,
      school: effectiveSchool.isNotEmpty ? effectiveSchool : null,
      classTeacher: _classTeacherCtrl.text.trim().isNotEmpty
          ? _classTeacherCtrl.text.trim()
          : null,
      parentContact: _parentContactCtrl.text.trim().isNotEmpty
          ? _parentContactCtrl.text.trim()
          : null,
    );

    if (success && mounted) {
      _navigateToHome();
    }
  }

  // ─── Parent Step 1: Send Real SMS OTP for Admission ID ─────────────────────
  Future<void> _handleSendParentOtp() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();
    final admission = _admissionIdCtrl.text.trim().toUpperCase();

    if (admission.isEmpty) {
      setState(() => _localError = 'Please enter the student admission number');
      return;
    }

    final success = await provider.sendParentRegistrationOtp(admission);
    if (success && mounted) {
      for (final c in _otpControllers) {
        c.clear();
      }
      final student = provider.regStudentProfile;
      if (student != null && student.parentContact.isNotEmpty) {
        _parentPhoneCtrl.text = student.parentContact;
      }
      setState(() {
        _parentStep = 2;
        _localError = null;
      });
      _startResendTimer();
      _otpFocusNodes[0].requestFocus();
    }
  }

  // ─── Parent Step 2: Verify Real SMS OTP ───────────────────────────────────
  Future<void> _handleVerifyParentOtp() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();
    final otp = _enteredOtp;

    if (otp.length < 6) {
      setState(() => _localError = 'Please enter the complete 6-digit OTP code');
      return;
    }

    final isValid = await provider.verifyParentRegistrationOtp(otp);
    if (isValid && mounted) {
      setState(() {
        _parentStep = 3;
        _localError = null;
      });
    }
  }

  // ─── Parent Step 3: Complete Parent Registration ───────────────────────────
  Future<void> _handleCompleteParentRegister() async {
    setState(() => _localError = null);
    final provider = context.read<AppProvider>();

    if (!_parentProfileFormKey.currentState!.validate()) return;

    final student = provider.regStudentProfile;
    final studentId = student?.id ?? _admissionIdCtrl.text.trim().toUpperCase();

    final success = await provider.register(
      name: _parentNameCtrl.text.trim(),
      username: _parentUsernameCtrl.text.trim(),
      password: _parentPasswordCtrl.text,
      role: UserRole.parent,
      studentId: studentId,
      school: student?.school,
      parentContact: _parentPhoneCtrl.text.trim().isNotEmpty
          ? _parentPhoneCtrl.text.trim()
          : provider.regRawPhone,
    );

    if (success && mounted) {
      provider.resetParentRegistrationState();
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;
    final displayError = _localError ?? provider.error;

    // Handle instant/auto verification on Android
    if (provider.regAutoVerified && _parentStep == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _parentStep == 2) {
          setState(() {
            _parentStep = 3;
            _localError = null;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark ? SAMSColors.bgDark : SAMSColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Bar with Back and Language Switcher ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? SAMSColors.bgDarkCard
                          : SAMSColors.bgLightCard,
                    ),
                  ),
                  _LanguagePills(provider: provider),
                ],
              ),
              const SizedBox(height: 18),

              // ─── Header Title ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SAMSStrings.registerTitle,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Student & Parent Mobile Portal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Error Banner ──────────────────────────────────────────────
              if (displayError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SAMSColors.absent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SAMSColors.absent.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline_rounded,
                            color: SAMSColors.absent, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: SAMSColors.absent,
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Role Selector (Student vs Parent) ─────────────────────────
              Text(
                SAMSStrings.roleSelect,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _RoleChips(
                selectedRole: _selectedRole,
                isDark: isDark,
                onRoleChanged: (role) {
                  setState(() {
                    _selectedRole = role;
                    _localError = null;
                    if (role == UserRole.parent) {
                      _parentStep = 1;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // ─── ROLE-BASED FLOW ───────────────────────────────────────────
              if (_selectedRole == UserRole.student) ...[
                _buildStudentRegistrationForm(provider, isDark),
              ] else ...[
                _buildParentRegistrationWorkflow(provider, isDark),
              ],

              const SizedBox(height: 20),

              // ─── Back to Login Link ────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    SAMSStrings.alreadyHaveAccount,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SAMSColors.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STUDENT REGISTRATION FORM (WITH PARENT-FIRST SECURITY CHECK)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStudentRegistrationForm(AppProvider provider, bool isDark) {
    return Form(
      key: _studentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Security Notice: Parent Verification Prerequisite ─────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SAMSColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SAMSColors.primary.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: SAMSColors.primaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Security Rule: Your parent must register first with your Admission Number before you can activate your student account.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      height: 1.35,
                      color: isDark
                          ? SAMSColors.textDarkSub
                          : SAMSColors.textLightSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Admission Number
          TextFormField(
            controller: _studentAdmissionCtrl,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return SAMSStrings.studentAdmissionRequired;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: SAMSStrings.linkedStudentId,
              hintText: SAMSStrings.studentAdmissionHint,
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Full Name
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter full name'
                : null,
            decoration: InputDecoration(
              labelText: SAMSStrings.fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Username
          TextFormField(
            controller: _usernameCtrl,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please choose a username';
              }
              if (v.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: SAMSStrings.username,
              prefixIcon:
                  const Icon(Icons.alternate_email_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 6) {
                return SAMSStrings.passwordTooShort;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: SAMSStrings.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── School Selector (Real Data from Firestore) ────────────────────
          if (_isLoadingSchools)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading registered schools...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                    ),
                  ),
                ],
              ),
            )
          else if (_schools.isNotEmpty && !_isCustomSchool)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedSchool),
                  initialValue: _selectedSchool,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.schoolLabel,
                    prefixIcon:
                        const Icon(Icons.account_balance_outlined, size: 20),
                  ),
                  items: [
                    ..._schools.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        )),
                    const DropdownMenuItem(
                      value: '__OTHER_SCHOOL__',
                      child: Text(
                        '+ Enter custom school name',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: SAMSColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == '__OTHER_SCHOOL__') {
                      setState(() {
                        _isCustomSchool = true;
                        _schoolCtrl.clear();
                      });
                      _updateClassTeacherSuggestion();
                    } else if (v != null) {
                      setState(() {
                        _selectedSchool = v;
                        _schoolCtrl.text = v;
                      });
                      _updateClassTeacherSuggestion();
                    }
                  },
                ),
              ],
            )
          else
            TextFormField(
              controller: _schoolCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: SAMSStrings.schoolLabel,
                hintText: 'Enter your school name',
                prefixIcon:
                    const Icon(Icons.account_balance_outlined, size: 20),
                suffixIcon: _schools.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.list_alt_rounded, size: 20),
                        tooltip: 'Choose from registered schools',
                        onPressed: () {
                          setState(() {
                            _isCustomSchool = false;
                            _selectedSchool = _schools.first;
                            _schoolCtrl.text = _schools.first;
                          });
                          _updateClassTeacherSuggestion();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                _updateClassTeacherSuggestion();
              },
            ),
          const SizedBox(height: 14),

          // ─── Grade & Class Row ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedGrade,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.gradeLabel,
                    prefixIcon:
                        const Icon(Icons.grade_outlined, size: 20),
                  ),
                  items: _grades
                      .map((g) => DropdownMenuItem(
                          value: g, child: Text('Grade $g')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedGrade = v;
                        if (!_selectedClass.startsWith(v)) {
                          _selectedClass = '${v}A';
                        }
                      });
                      _updateClassTeacherSuggestion();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.classRoomLabel,
                    prefixIcon:
                        const Icon(Icons.meeting_room_outlined, size: 20),
                  ),
                  items: _classes
                      .where((c) => c.startsWith(_selectedGrade))
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text('Class $c')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedClass = v);
                      _updateClassTeacherSuggestion();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Auto-Suggested Class Teacher Field (Real Data) ───────────────
          TextFormField(
            controller: _classTeacherCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: SAMSStrings.classTeacherLabel,
              hintText: 'Enter your class teacher name (auto-filled if registered)',
              helperText: _classTeacherCtrl.text.isNotEmpty
                  ? SAMSStrings.classTeacherSuggested
                  : 'Enter your assigned class teacher name',
              helperStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _classTeacherCtrl.text.isNotEmpty
                    ? SAMSColors.primaryLight
                    : (isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon:
                  const Icon(Icons.person_pin_rounded, size: 20),
              suffixIcon: _isAutoSuggestingTeacher
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_classTeacherCtrl.text.isNotEmpty
                      ? const Tooltip(
                          message: 'Matched from school teacher records',
                          child: Icon(Icons.verified_user_rounded,
                              size: 18, color: SAMSColors.present),
                        )
                      : null),
            ),
          ),
          const SizedBox(height: 14),

          // Parent Contact
          TextFormField(
            controller: _parentContactCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: SAMSStrings.parentContactLabel,
              hintText: 'e.g. 0771234567 (Optional if on parent record)',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _handleStudentRegister,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      SAMSStrings.register,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PARENT REGISTRATION WORKFLOW (ADMISSION -> REAL SMS OTP -> ACCOUNT SETUP)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildParentRegistrationWorkflow(
      AppProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Step Progress Indicator ──────────────────────────────────────────
        _ParentStepIndicator(
          currentStep: _parentStep,
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // ── STEP 1: Enter Student Admission Number ───────────────────────────
        if (_parentStep == 1) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SAMSColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.badge_rounded,
                          color: SAMSColors.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SAMSStrings.linkedStudentId,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Enter your child\'s student admission number on school record (e.g. ADM-44424)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: isDark
                                  ? SAMSColors.textDarkSub
                                  : SAMSColors.textLightSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _admissionIdCtrl,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _handleSendParentOtp(),
                  decoration: InputDecoration(
                    labelText: SAMSStrings.linkedStudentId,
                    hintText: SAMSStrings.studentAdmissionHint,
                    prefixIcon:
                        const Icon(Icons.school_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        provider.isLoading ? null : _handleSendParentOtp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                SAMSStrings.verifyAdmissionNumber,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── STEP 2: Real SMS OTP Verification ────────────────────────────────
        if (_parentStep == 2) ...[
          // Verified Student Preview Card
          if (provider.regStudentProfile != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SAMSColors.present.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: SAMSColors.present.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SAMSColors.present.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: SAMSColors.present, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${SAMSStrings.studentFound}: ${provider.regStudentProfile!.name}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grade ${provider.regStudentProfile!.grade} - Class ${provider.regStudentProfile!.classRoom} (Admission No: ${provider.regStudentProfile!.id})',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: isDark
                                ? SAMSColors.textDarkSub
                                : SAMSColors.textLightSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // OTP Sent Info Card with Masked Phone
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_android_rounded,
                    color: SAMSColors.primaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SAMSStrings.parentOtpSentTo,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.regMaskedPhone ?? 'Registered Phone',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Notice Banner (Real SMS or auto fallback if Firebase Phone Auth is disabled in console)
          if (provider.regFallbackOtp != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OTP Verification Code (Console Fallback):',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'OTP: ${provider.regFallbackOtp}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final code = provider.regFallbackOtp;
                      if (code != null && code.length == 6) {
                        for (int i = 0; i < 6; i++) {
                          _otpControllers[i].text = code[i];
                        }
                        _handleVerifyParentOtp();
                      }
                    },
                    child: const Text('Auto-Fill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SAMSColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SAMSColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SAMSColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_rounded, color: SAMSColors.primaryLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'An SMS verification code has been sent to your registered phone. Please enter the 6-digit code below.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.35,
                        color: isDark ? SAMSColors.textDarkSub : SAMSColors.textLightSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 6-digit OTP Box Inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                height: 56,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isDark
                        ? SAMSColors.bgDarkCard
                        : SAMSColors.bgLightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: SAMSColors.primaryLight,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty) {
                      if (index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else {
                        _otpFocusNodes[index].unfocus();
                        _handleVerifyParentOtp();
                      }
                    } else {
                      if (index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Verify OTP Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  provider.isLoading ? null : _handleVerifyParentOtp,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          SAMSStrings.verifyOtp,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Change Admission Number & Resend OTP Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _parentStep = 1;
                    _localError = null;
                  });
                },
                child: Text(
                  SAMSStrings.changeAdmissionNumber,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: isDark
                        ? SAMSColors.textDarkSub
                        : SAMSColors.textLightSub,
                  ),
                ),
              ),
              _canResend
                  ? TextButton(
                      onPressed: provider.isLoading
                          ? null
                          : _handleSendParentOtp,
                      child: Text(
                        SAMSStrings.resendOtp,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: SAMSColors.primaryLight,
                        ),
                      ),
                    )
                  : Text(
                      '${SAMSStrings.resendIn} ${_resendCountdown}s',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark
                            ? SAMSColors.textDarkSub
                            : SAMSColors.textLightSub,
                      ),
                    ),
            ],
          ),
        ],

        // ── STEP 3: Complete Parent Account Setup ────────────────────────────
        if (_parentStep == 3) ...[
          // Linked Student Verification Success Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SAMSColors.present.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: SAMSColors.present.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: SAMSColors.present, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified for ${provider.regStudentProfile?.name ?? "Student"}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SAMSColors.present,
                        ),
                      ),
                      Text(
                        'Admission Number: ${provider.regStudentProfile?.id ?? _admissionIdCtrl.text.trim().toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Form(
            key: _parentProfileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SAMSStrings.parentAccountDetails,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SAMSStrings.parentAccountSub,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark
                        ? SAMSColors.textDarkSub
                        : SAMSColors.textLightSub,
                  ),
                ),
                const SizedBox(height: 16),

                // Parent Full Name
                TextFormField(
                  controller: _parentNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your full name'
                      : null,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.parentFullName,
                    prefixIcon:
                        const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Parent Username
                TextFormField(
                  controller: _parentUsernameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please choose a parent username';
                    }
                    if (v.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: SAMSStrings.username,
                    prefixIcon: const Icon(Icons.alternate_email_rounded,
                        size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Parent Password
                TextFormField(
                  controller: _parentPasswordCtrl,
                  obscureText: !_showParentPassword,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (v.length < 6) {
                      return SAMSStrings.passwordTooShort;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: SAMSStrings.password,
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showParentPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          _showParentPassword = !_showParentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Parent Contact Number
                TextFormField(
                  controller: _parentPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your contact phone'
                      : null,
                  decoration: InputDecoration(
                    labelText: SAMSStrings.parentContactLabel,
                    prefixIcon:
                        const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Complete Registration Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : _handleCompleteParentRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            SAMSStrings.completeRegistration,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PARENT STEP INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _ParentStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const _ParentStepIndicator({
    required this.currentStep,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (1, SAMSStrings.step1Admission, Icons.badge_outlined),
      (2, SAMSStrings.step2Otp, Icons.mark_email_read_outlined),
      (3, SAMSStrings.step3Profile, Icons.person_add_alt_1_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? SAMSColors.bgDarkCard : SAMSColors.bgLightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map((s) {
          final isDone = currentStep > s.$1;
          final isActive = currentStep == s.$1;

          final color = isActive
              ? SAMSColors.primaryLight
              : isDone
                  ? SAMSColors.present
                  : (isDark ? Colors.white38 : Colors.black38);

          return Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isActive
                        ? SAMSColors.primary.withOpacity(0.2)
                        : isDone
                            ? SAMSColors.present.withOpacity(0.15)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: isActive || isDone ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 14, color: SAMSColors.present)
                        : Text(
                            '${s.$1}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _RoleChips extends StatelessWidget {
  final UserRole selectedRole;
  final bool isDark;
  final ValueChanged<UserRole> onRoleChanged;

  const _RoleChips({
    required this.selectedRole,
    required this.isDark,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      (UserRole.student, SAMSStrings.roleStudent, Icons.school_rounded),
      (UserRole.parent, SAMSStrings.roleParent, Icons.family_restroom_rounded),
    ];

    return Row(
      children: roles.map((r) {
        final isSelected = selectedRole == r.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onRoleChanged(r.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? SAMSColors.primary
                    : (isDark
                        ? SAMSColors.bgDarkCard
                        : SAMSColors.bgLightCard),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? SAMSColors.primaryLight
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    r.$3,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? SAMSColors.textDarkSub
                            : SAMSColors.textLightSub),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.$2,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? SAMSColors.textDarkSub
                              : SAMSColors.textLightSub),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE PILLS
// ─────────────────────────────────────────────────────────────────────────────
class _LanguagePills extends StatelessWidget {
  final AppProvider provider;
  const _LanguagePills({required this.provider});

  @override
  Widget build(BuildContext context) {
    final langs = [
      (AppLanguage.english, 'EN'),
      (AppLanguage.sinhala, 'SI'),
      (AppLanguage.tamil, 'TA'),
    ];
    return Row(
      children: langs.map((l) {
        final isActive = provider.language == l.$1;
        return GestureDetector(
          onTap: () => provider.setLanguage(l.$1),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? SAMSColors.primary
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              l.$2,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : (provider.isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
